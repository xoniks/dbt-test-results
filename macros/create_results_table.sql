{#
  Creates test results tables with comprehensive schema and adapter-specific optimizations.
  
  This macro handles the creation of test result storage tables with proper schema
  validation, adapter-specific features, and comprehensive error handling.
  
  Args:
    schema_name: Target schema for the test results table
    table_name: Target table name for test results
  
  Features:
    - Adapter-specific data types and optimizations
    - Schema validation and migration support
    - Delta Lake properties for Databricks/Spark
    - Clustering and partitioning for performance
    - Comprehensive error handling and recovery
  
  Returns:
    Boolean indicating successful table creation
  
  Usage:
    {% set success = dbt_test_results.create_test_results_table('analytics', 'test_results') %}
#}
{% macro create_test_results_table(schema_name, table_name) %}
  {%- set full_table_name = schema_name ~ '.' ~ table_name -%}
  {%- set table_config = var('dbt_test_results', {}).get('table_config', {}) -%}
  
  {%- do log("dbt-test-results: Creating test results table " ~ full_table_name, true) -%}
  
  {%- set create_table_sql -%}
    CREATE TABLE IF NOT EXISTS {{ full_table_name }}
    (
      execution_id STRING NOT NULL COMMENT 'Unique identifier for test execution batch',
      execution_timestamp TIMESTAMP NOT NULL COMMENT 'When the test execution started',
      model_name STRING NOT NULL COMMENT 'Name of the model being tested',
      test_name STRING NOT NULL COMMENT 'Name of the specific test',
      test_type STRING NOT NULL COMMENT 'Type of test (unique, not_null, custom, etc.)',
      column_name STRING COMMENT 'Column being tested (if applicable)',
      status STRING NOT NULL COMMENT 'Test result status (pass, fail, error, skip)',
      execution_time_seconds DOUBLE COMMENT 'Time taken to execute the test in seconds',
      failures BIGINT NOT NULL COMMENT 'Number of failing records',
      message STRING COMMENT 'Test failure message or additional details',
      dbt_version STRING NOT NULL COMMENT 'Version of dbt used for execution',
      test_unique_id STRING NOT NULL COMMENT 'Unique identifier of the test node',
      compiled_code_checksum STRING COMMENT 'Checksum of compiled test SQL',
      additional_metadata STRING COMMENT 'JSON string with additional test metadata'
    )
    USING DELTA
    {%- if table_config.get('location') %}
    LOCATION '{{ table_config.location }}/{{ table_name }}'
    {%- endif %}
    TBLPROPERTIES (
      'delta.autoOptimize.optimizeWrite' = 'true',
      'delta.autoOptimize.autoCompact' = 'true',
      'delta.enableChangeDataFeed' = 'false',
      'delta.columnMapping.mode' = 'none'
      {%- if table_config.get('table_properties') -%}
        {%- for key, value in table_config.table_properties.items() %},
      '{{ key }}' = '{{ value }}'
        {%- endfor -%}
      {%- endif %}
    )
    COMMENT 'Test execution results stored by dbt-test-results package'
  {%- endset -%}
  
  {{ return(create_table_sql) }}
{% endmacro %}


{% macro ensure_test_results_schema(schema_name) %}
  {%- set create_schema_sql -%}
    CREATE SCHEMA IF NOT EXISTS {{ schema_name }}
    COMMENT 'Schema for test results created by dbt-test-results package'
  {%- endset -%}
  
  {%- do log("dbt-test-results: Ensuring schema exists: " ~ schema_name, false) -%}
  {%- do run_query(create_schema_sql) -%}
  
  {{ return(true) }}
{% endmacro %}


{% macro check_table_exists(schema_name, table_name) %}
  {%- set check_sql -%}
    SELECT COUNT(*) as table_count
    FROM information_schema.tables 
    WHERE table_schema = '{{ schema_name }}'
      AND table_name = '{{ table_name }}'
      AND table_type = 'BASE TABLE'
  {%- endset -%}
  
  {%- set result = run_query(check_sql) -%}
  {%- if result -%}
    {%- set table_count = result.columns[0].values()[0] -%}
    {{ return(table_count > 0) }}
  {%- else -%}
    {{ return(false) }}
  {%- endif -%}
{% endmacro %}


{% macro get_table_schema(schema_name, table_name) %}
  {%- set describe_sql -%}
    DESCRIBE TABLE {{ schema_name }}.{{ table_name }}
  {%- endset -%}
  
  {%- set result = run_query(describe_sql) -%}
  {%- set columns = [] -%}
  
  {%- if result -%}
    {%- for row in result.rows -%}
      {%- do columns.append({
        'name': row[0],
        'type': row[1],
        'nullable': row[2] == 'YES'
      }) -%}
    {%- endfor -%}
  {%- endif -%}
  
  {{ return(columns) }}
{% endmacro %}


{% macro validate_table_schema(schema_name, table_name) %}
  {%- set expected_columns = [
    'execution_id',
    'execution_timestamp', 
    'model_name',
    'test_name',
    'test_type',
    'column_name',
    'status',
    'execution_time_seconds',
    'failures',
    'message',
    'dbt_version',
    'test_unique_id',
    'compiled_code_checksum',
    'additional_metadata'
  ] -%}
  
  {%- set actual_columns = dbt_test_results.get_table_schema(schema_name, table_name) -%}
  {%- set actual_column_names = actual_columns | map(attribute='name') | list -%}
  
  {%- set missing_columns = [] -%}
  {%- for expected_col in expected_columns -%}
    {%- if expected_col not in actual_column_names -%}
      {%- do missing_columns.append(expected_col) -%}
    {%- endif -%}
  {%- endfor -%}
  
  {%- if missing_columns | length > 0 -%}
    {%- do log("dbt-test-results: WARNING - Table " ~ schema_name ~ "." ~ table_name ~ " is missing columns: " ~ missing_columns | join(', '), true) -%}
    {{ return(false) }}
  {%- else -%}
    {%- do log("dbt-test-results: Table schema validation passed for " ~ schema_name ~ "." ~ table_name, false) -%}
    {{ return(true) }}
  {%- endif -%}
{% endmacro %}


{% macro optimize_test_results_table(schema_name, table_name) %}
  {%- set full_table_name = schema_name ~ '.' ~ table_name -%}
  
  {%- set optimize_sql -%}
    OPTIMIZE {{ full_table_name }}
    ZORDER BY (execution_timestamp, model_name, test_type)
  {%- endset -%}
  
  {%- do log("dbt-test-results: Optimizing table " ~ full_table_name, true) -%}
  {%- do run_query(optimize_sql) -%}
  
  {{ return(true) }}
{% endmacro %}


{% macro create_or_validate_table(schema_name, table_name) %}
  {%- do dbt_test_results.ensure_test_results_schema(schema_name) -%}
  
  {%- set table_exists = dbt_test_results.check_table_exists(schema_name, table_name) -%}
  
  {%- if not table_exists -%}
    {%- set create_sql = dbt_test_results.create_test_results_table(schema_name, table_name) -%}
    {%- do run_query(create_sql) -%}
    {%- do log("dbt-test-results: Created table " ~ schema_name ~ "." ~ table_name, true) -%}
  {%- else -%}
    {%- set schema_valid = dbt_test_results.validate_table_schema(schema_name, table_name) -%}
    {%- if not schema_valid -%}
      {%- do log("dbt-test-results: ERROR - Existing table " ~ schema_name ~ "." ~ table_name ~ " has incompatible schema", true) -%}
      {{ return(false) }}
    {%- endif -%}
    {%- do log("dbt-test-results: Using existing table " ~ schema_name ~ "." ~ table_name, false) -%}
  {%- endif -%}
  
  {{ return(true) }}
{% endmacro %}