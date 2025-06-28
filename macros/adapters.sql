{#
  Multi-adapter framework for dbt-test-results package.
  
  This file provides adapter-specific implementations using dbt's dispatch pattern
  to support multiple database platforms while maintaining a consistent interface.
#}

{#
  Creates a test results table with adapter-specific optimizations.
  
  This macro uses dbt's dispatch pattern to delegate to adapter-specific implementations
  while providing a consistent interface across all supported adapters.
  
  Args:
    schema_name: Target schema name
    table_name: Target table name
    
  Returns:
    SQL string for creating the table
    
  Usage:
    {% set create_sql = dbt_test_results.create_test_results_table_dispatch(schema, table) %}
#}
{% macro create_test_results_table_dispatch(schema_name, table_name) %}
  {{ return(adapter.dispatch('create_test_results_table_impl', 'dbt_test_results')(schema_name, table_name)) }}
{% endmacro %}


{#
  Default implementation for creating test results table.
  
  This provides a generic implementation that works across most adapters.
  Adapter-specific macros can override this for optimizations.
#}
{% macro default__create_test_results_table_impl(schema_name, table_name) %}
  {%- set full_table_name = schema_name ~ '.' ~ table_name -%}
  {%- set table_config = var('dbt_test_results', {}).get('table_config', {}) -%}
  
  {%- do dbt_test_results.log_message('info', 'Creating test results table with default implementation: ' ~ full_table_name) -%}
  
  {%- set create_table_sql -%}
    CREATE TABLE IF NOT EXISTS {{ full_table_name }}
    (
      execution_id STRING NOT NULL,
      execution_timestamp TIMESTAMP NOT NULL,
      model_name STRING NOT NULL,
      test_name STRING NOT NULL,
      test_type STRING NOT NULL,
      column_name STRING,
      status STRING NOT NULL,
      execution_time_seconds DOUBLE,
      failures BIGINT NOT NULL DEFAULT 0,
      message STRING,
      dbt_version STRING NOT NULL,
      test_unique_id STRING NOT NULL,
      compiled_code_checksum STRING,
      additional_metadata STRING
    )
  {%- endset -%}
  
  {{ return(create_table_sql) }}
{% endmacro %}


{#
  Databricks/Spark-specific implementation for creating test results table.
  
  Optimized for Databricks with Delta Lake features and partitioning.
#}
{% macro spark__create_test_results_table_impl(schema_name, table_name) %}
  {%- set full_table_name = schema_name ~ '.' ~ table_name -%}
  {%- set table_config = var('dbt_test_results', {}).get('table_config', {}) -%}
  
  {%- do dbt_test_results.log_message('info', 'Creating test results table with Spark/Databricks optimizations: ' ~ full_table_name) -%}
  
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
      failures BIGINT NOT NULL DEFAULT 0 COMMENT 'Number of failing records',
      message STRING COMMENT 'Test failure message or additional details',
      dbt_version STRING NOT NULL COMMENT 'Version of dbt used for execution',
      test_unique_id STRING NOT NULL COMMENT 'Unique identifier of the test node',
      compiled_code_checksum STRING COMMENT 'Checksum of compiled test SQL',
      additional_metadata STRING COMMENT 'JSON string with additional test metadata'
    )
    USING {{ table_config.get('file_format', 'DELTA') }}
    {%- if table_config.get('location') %}
    LOCATION '{{ table_config.location }}/{{ table_name }}'
    {%- endif %}
    PARTITIONED BY (DATE(execution_timestamp))
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


{#
  BigQuery-specific implementation for creating test results table.
  
  Optimized for BigQuery with partitioning and clustering.
#}
{% macro bigquery__create_test_results_table_impl(schema_name, table_name) %}
  {%- set full_table_name = schema_name ~ '.' ~ table_name -%}
  {%- set table_config = var('dbt_test_results', {}).get('table_config', {}) -%}
  
  {%- do dbt_test_results.log_message('info', 'Creating test results table with BigQuery optimizations: ' ~ full_table_name) -%}
  
  {%- set create_table_sql -%}
    CREATE TABLE IF NOT EXISTS {{ full_table_name }}
    (
      execution_id STRING NOT NULL OPTIONS(description="Unique identifier for test execution batch"),
      execution_timestamp TIMESTAMP NOT NULL OPTIONS(description="When the test execution started"),
      model_name STRING NOT NULL OPTIONS(description="Name of the model being tested"),
      test_name STRING NOT NULL OPTIONS(description="Name of the specific test"),
      test_type STRING NOT NULL OPTIONS(description="Type of test (unique, not_null, custom, etc.)"),
      column_name STRING OPTIONS(description="Column being tested (if applicable)"),
      status STRING NOT NULL OPTIONS(description="Test result status (pass, fail, error, skip)"),
      execution_time_seconds FLOAT64 OPTIONS(description="Time taken to execute the test in seconds"),
      failures INT64 NOT NULL DEFAULT 0 OPTIONS(description="Number of failing records"),
      message STRING OPTIONS(description="Test failure message or additional details"),
      dbt_version STRING NOT NULL OPTIONS(description="Version of dbt used for execution"),
      test_unique_id STRING NOT NULL OPTIONS(description="Unique identifier of the test node"),
      compiled_code_checksum STRING OPTIONS(description="Checksum of compiled test SQL"),
      additional_metadata JSON OPTIONS(description="JSON object with additional test metadata")
    )
    PARTITION BY DATE(execution_timestamp)
    CLUSTER BY model_name, test_type, status
    OPTIONS(
      description="Test execution results stored by dbt-test-results package",
      labels=[("package", "dbt_test_results"), ("purpose", "data_quality")]
    )
  {%- endset -%}
  
  {{ return(create_table_sql) }}
{% endmacro %}


{#
  Snowflake-specific implementation for creating test results table.
  
  Optimized for Snowflake with clustering and time travel.
#}
{% macro snowflake__create_test_results_table_impl(schema_name, table_name) %}
  {%- set full_table_name = schema_name ~ '.' ~ table_name -%}
  {%- set table_config = var('dbt_test_results', {}).get('table_config', {}) -%}
  
  {%- do dbt_test_results.log_message('info', 'Creating test results table with Snowflake optimizations: ' ~ full_table_name) -%}
  
  {%- set create_table_sql -%}
    CREATE TABLE IF NOT EXISTS {{ full_table_name }}
    (
      execution_id VARCHAR NOT NULL COMMENT 'Unique identifier for test execution batch',
      execution_timestamp TIMESTAMP_NTZ NOT NULL COMMENT 'When the test execution started',
      model_name VARCHAR NOT NULL COMMENT 'Name of the model being tested',
      test_name VARCHAR NOT NULL COMMENT 'Name of the specific test',
      test_type VARCHAR NOT NULL COMMENT 'Type of test (unique, not_null, custom, etc.)',
      column_name VARCHAR COMMENT 'Column being tested (if applicable)',
      status VARCHAR NOT NULL COMMENT 'Test result status (pass, fail, error, skip)',
      execution_time_seconds DOUBLE COMMENT 'Time taken to execute the test in seconds',
      failures BIGINT NOT NULL DEFAULT 0 COMMENT 'Number of failing records',
      message VARCHAR COMMENT 'Test failure message or additional details',
      dbt_version VARCHAR NOT NULL COMMENT 'Version of dbt used for execution',
      test_unique_id VARCHAR NOT NULL COMMENT 'Unique identifier of the test node',
      compiled_code_checksum VARCHAR COMMENT 'Checksum of compiled test SQL',
      additional_metadata VARIANT COMMENT 'JSON object with additional test metadata'
    )
    CLUSTER BY (DATE(execution_timestamp), model_name, test_type)
    COMMENT = 'Test execution results stored by dbt-test-results package'
  {%- endset -%}
  
  {{ return(create_table_sql) }}
{% endmacro %}


{#
  PostgreSQL-specific implementation for creating test results table.
  
  Optimized for PostgreSQL with indexing and JSONB.
#}
{% macro postgres__create_test_results_table_impl(schema_name, table_name) %}
  {%- set full_table_name = schema_name ~ '.' ~ table_name -%}
  {%- set table_config = var('dbt_test_results', {}).get('table_config', {}) -%}
  
  {%- do dbt_test_results.log_message('info', 'Creating test results table with PostgreSQL optimizations: ' ~ full_table_name) -%}
  
  {%- set create_table_sql -%}
    CREATE TABLE IF NOT EXISTS {{ full_table_name }}
    (
      execution_id VARCHAR NOT NULL,
      execution_timestamp TIMESTAMP NOT NULL,
      model_name VARCHAR NOT NULL,
      test_name VARCHAR NOT NULL,
      test_type VARCHAR NOT NULL,
      column_name VARCHAR,
      status VARCHAR NOT NULL,
      execution_time_seconds DOUBLE PRECISION,
      failures BIGINT NOT NULL DEFAULT 0,
      message TEXT,
      dbt_version VARCHAR NOT NULL,
      test_unique_id VARCHAR NOT NULL,
      compiled_code_checksum VARCHAR,
      additional_metadata JSONB
    );
    
    -- Create indexes for better query performance
    CREATE INDEX IF NOT EXISTS idx_{{ table_name }}_execution_timestamp 
      ON {{ full_table_name }} (execution_timestamp);
    CREATE INDEX IF NOT EXISTS idx_{{ table_name }}_model_status 
      ON {{ full_table_name }} (model_name, status);
    CREATE INDEX IF NOT EXISTS idx_{{ table_name }}_test_type 
      ON {{ full_table_name }} (test_type);
    
    -- Comment on table
    COMMENT ON TABLE {{ full_table_name }} 
      IS 'Test execution results stored by dbt-test-results package'
  {%- endset -%}
  
  {{ return(create_table_sql) }}
{% endmacro %}


{#
  Adapter-specific batch insert optimization.
  
  Uses dispatch pattern to provide optimized insert strategies per adapter.
  
  Args:
    schema_name: Target schema
    table_name: Target table
    test_results: List of test results to insert
    
  Returns:
    Number of records inserted
#}
{% macro insert_test_results_dispatch(schema_name, table_name, test_results) %}
  {{ return(adapter.dispatch('insert_test_results_impl', 'dbt_test_results')(schema_name, table_name, test_results)) }}
{% endmacro %}


{#
  Default implementation for batch insert.
#}
{% macro default__insert_test_results_impl(schema_name, table_name, test_results) %}
  {{ return(dbt_test_results.insert_test_results(schema_name, table_name, test_results)) }}
{% endmacro %}


{#
  Spark/Databricks-specific insert optimization.
  
  Uses Delta Lake MERGE for better concurrency and deduplication.
#}
{% macro spark__insert_test_results_impl(schema_name, table_name, test_results) %}
  {%- set use_merge_strategy = dbt_test_results.get_config('use_merge_strategy', true) -%}
  
  {%- if use_merge_strategy -%}
    {{ return(dbt_test_results.merge_test_results(schema_name, table_name, test_results)) }}
  {%- else -%}
    {{ return(dbt_test_results.insert_test_results(schema_name, table_name, test_results)) }}
  {%- endif -%}
{% endmacro %}


{#
  BigQuery-specific insert optimization.
  
  Uses streaming inserts for better performance with large datasets.
#}
{% macro bigquery__insert_test_results_impl(schema_name, table_name, test_results) %}
  {%- set full_table_name = schema_name ~ '.' ~ table_name -%}
  {%- set use_streaming_inserts = dbt_test_results.get_config('use_streaming_inserts', false) -%}
  
  {%- if use_streaming_inserts -%}
    {%- do dbt_test_results.log_message('info', 'Using BigQuery streaming inserts for ' ~ full_table_name) -%}
  {%- endif -%}
  
  {{ return(dbt_test_results.insert_test_results(schema_name, table_name, test_results)) }}
{% endmacro %}


{#
  Gets adapter-specific configuration and capabilities.
  
  Returns:
    Dictionary with adapter capabilities and recommended settings
    
  Usage:
    {% set adapter_info = dbt_test_results.get_adapter_capabilities() %}
#}
{% macro get_adapter_capabilities() %}
  {{ return(adapter.dispatch('get_adapter_capabilities_impl', 'dbt_test_results')()) }}
{% endmacro %}


{#
  Default adapter capabilities.
#}
{% macro default__get_adapter_capabilities_impl() %}
  {%- set capabilities = {
    'adapter_type': target.type,
    'supports_merge': false,
    'supports_partitioning': false,
    'supports_clustering': false,
    'supports_json': false,
    'max_batch_size': 1000,
    'recommended_batch_size': 500,
    'supports_parallel_processing': false,
    'supports_streaming_inserts': false
  } -%}
  
  {{ return(capabilities) }}
{% endmacro %}


{#
  Spark/Databricks adapter capabilities.
#}
{% macro spark__get_adapter_capabilities_impl() %}
  {%- set capabilities = {
    'adapter_type': 'spark',
    'supports_merge': true,
    'supports_partitioning': true,
    'supports_clustering': false,
    'supports_json': true,
    'max_batch_size': 10000,
    'recommended_batch_size': 5000,
    'supports_parallel_processing': true,
    'supports_streaming_inserts': false,
    'supports_delta_optimizations': true,
    'supports_vacuum': true
  } -%}
  
  {{ return(capabilities) }}
{% endmacro %}


{#
  BigQuery adapter capabilities.
#}
{% macro bigquery__get_adapter_capabilities_impl() %}
  {%- set capabilities = {
    'adapter_type': 'bigquery',
    'supports_merge': true,
    'supports_partitioning': true,
    'supports_clustering': true,
    'supports_json': true,
    'max_batch_size': 50000,
    'recommended_batch_size': 10000,
    'supports_parallel_processing': true,
    'supports_streaming_inserts': true,
    'supports_time_travel': true
  } -%}
  
  {{ return(capabilities) }}
{% endmacro %}


{#
  Snowflake adapter capabilities.
#}
{% macro snowflake__get_adapter_capabilities_impl() %}
  {%- set capabilities = {
    'adapter_type': 'snowflake',
    'supports_merge': true,
    'supports_partitioning': false,
    'supports_clustering': true,
    'supports_json': true,
    'max_batch_size': 25000,
    'recommended_batch_size': 5000,
    'supports_parallel_processing': true,
    'supports_streaming_inserts': false,
    'supports_time_travel': true,
    'supports_zero_copy_cloning': true
  } -%}
  
  {{ return(capabilities) }}
{% endmacro %}


{#
  PostgreSQL adapter capabilities.
#}
{% macro postgres__get_adapter_capabilities_impl() %}
  {%- set capabilities = {
    'adapter_type': 'postgres',
    'supports_merge': true,
    'supports_partitioning': true,
    'supports_clustering': false,
    'supports_json': true,
    'max_batch_size': 5000,
    'recommended_batch_size': 1000,
    'supports_parallel_processing': false,
    'supports_streaming_inserts': false,
    'supports_jsonb': true,
    'supports_gin_indexes': true
  } -%}
  
  {{ return(capabilities) }}
{% endmacro %}


{#
  Automatically configures optimal settings based on adapter capabilities.
  
  Returns:
    Dictionary with recommended configuration values
    
  Usage:
    {% set optimal_config = dbt_test_results.get_optimal_configuration() %}
#}
{% macro get_optimal_configuration() %}
  {%- set adapter_caps = dbt_test_results.get_adapter_capabilities() -%}
  {%- set current_config = var('dbt_test_results', {}) -%}
  
  {%- set optimal_config = {
    'batch_size': adapter_caps.get('recommended_batch_size', 1000),
    'use_merge_strategy': adapter_caps.get('supports_merge', false),
    'enable_parallel_processing': adapter_caps.get('supports_parallel_processing', false),
    'max_batch_size': adapter_caps.get('max_batch_size', 5000)
  } -%}
  
  {# Override with user configuration #}
  {%- for key, value in current_config.items() -%}
    {%- set _ = optimal_config.update({key: value}) -%}
  {%- endfor -%}
  
  {%- do dbt_test_results.log_message('debug', 'Optimal configuration for ' ~ adapter_caps.adapter_type ~ ': ' ~ optimal_config | tojson) -%}
  
  {{ return(optimal_config) }}
{% endmacro %}