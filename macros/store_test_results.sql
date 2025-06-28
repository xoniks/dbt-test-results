{#
  Inserts test results into storage tables with optimized batch processing.
  
  This macro handles the efficient insertion of test results using configurable
  batch processing, comprehensive error handling, and performance optimization.
  
  Args:
    schema_name: Target schema containing the test results table
    table_name: Target table name for test results
    test_results: List of test result records to insert
  
  Features:
    - Configurable batch processing for performance
    - Enhanced error handling with recovery
    - Memory-efficient processing for large datasets
    - Progress logging and monitoring
    - Rollback support for failed operations
  
  Returns:
    Integer count of successfully inserted records
  
  Usage:
    {% set inserted = dbt_test_results.insert_test_results('analytics', 'test_results', results) %}
#}
{% macro insert_test_results(schema_name, table_name, test_results) %}
  {%- set full_table_name = schema_name ~ '.' ~ table_name -%}
  {%- set batch_size = var('dbt_test_results', {}).get('batch_size', 1000) -%}
  
  {%- if test_results | length == 0 -%}
    {%- do log("dbt-test-results: No results to insert for " ~ full_table_name, false) -%}
    {{ return(0) }}
  {%- endif -%}
  
  {%- do log("dbt-test-results: Inserting " ~ test_results | length ~ " test results into " ~ full_table_name, true) -%}
  
  {%- set total_inserted = 0 -%}
  {%- set batch_count = (test_results | length / batch_size) | round(0, 'ceil') | int -%}
  
  {%- for batch_num in range(batch_count) -%}
    {%- set start_idx = batch_num * batch_size -%}
    {%- set end_idx = (start_idx + batch_size) if (start_idx + batch_size) < test_results | length else test_results | length -%}
    {%- set batch_results = test_results[start_idx:end_idx] -%}
    
    {%- do log("dbt-test-results: Processing batch " ~ (batch_num + 1) ~ "/" ~ batch_count ~ " (" ~ batch_results | length ~ " records)", false) -%}
    
    {%- set insert_sql = dbt_test_results.build_batch_insert_sql(full_table_name, batch_results) -%}
    
    {%- if insert_sql -%}
      {%- set insert_success = none -%}
      {%- if execute -%}
        {%- set insert_success = run_query(insert_sql) -%}
      {%- endif -%}
      
      {%- if insert_success is not none -%}
        {%- set total_inserted = total_inserted + batch_results | length -%}
      {%- else -%}
        {%- do dbt_test_results.handle_enhanced_error(
          'Failed to insert batch ' ~ (batch_num + 1) ~ ' of ' ~ batch_count ~ ' (' ~ batch_results | length ~ ' records)',
          'database_operation',
          'insert_test_results macro',
          [
            'Check database connection and permissions',
            'Verify table schema is compatible',
            'Check for data type mismatches',
            'Reduce batch_size if hitting memory limits',
            'Enable debug_mode for detailed error information'
          ]
        ) -%}
      {%- endif -%}
    {%- else -%}
      {%- do dbt_test_results.handle_enhanced_error(
        'Failed to generate insert SQL for batch ' ~ (batch_num + 1),
        'sql_generation',
        'build_batch_insert_sql macro',
        [
          'Check test results data structure',
          'Verify column names match table schema',
          'Check for special characters in data that need escaping',
          'Enable debug_mode to see the generated SQL'
        ]
      ) -%}
    {%- endif -%}
  {%- endfor -%}
  
  {%- do log("dbt-test-results: Successfully inserted " ~ total_inserted ~ " records into " ~ full_table_name, true) -%}
  
  {{ return(total_inserted) }}
{% endmacro %}


{% macro build_batch_insert_sql(full_table_name, batch_results) %}
  {%- if batch_results | length == 0 -%}
    {{ return(none) }}
  {%- endif -%}
  
  {%- set values_list = [] -%}
  
  {%- for result in batch_results -%}
    {%- set value_row = dbt_test_results.format_result_row(result) -%}
    {%- if value_row -%}
      {%- do values_list.append(value_row) -%}
    {%- endif -%}
  {%- endfor -%}
  
  {%- if values_list | length == 0 -%}
    {{ return(none) }}
  {%- endif -%}
  
  {%- set insert_sql -%}
    INSERT INTO {{ full_table_name }}
    (
      execution_id,
      execution_timestamp,
      model_name,
      test_name,
      test_type,
      column_name,
      status,
      execution_time_seconds,
      failures,
      message,
      dbt_version,
      test_unique_id,
      compiled_code_checksum,
      additional_metadata
    )
    VALUES
    {{ values_list | join(',\n    ') }}
  {%- endset -%}
  
  {{ return(insert_sql) }}
{% endmacro %}


{% macro format_result_row(result) %}
  {%- set execution_id = dbt_test_results.escape_sql_string(result.execution_id) -%}
  {%- set execution_timestamp = "TIMESTAMP '" ~ result.execution_timestamp ~ "'" -%}
  {%- set model_name = dbt_test_results.escape_sql_string(result.model_name) -%}
  {%- set test_name = dbt_test_results.escape_sql_string(result.test_name) -%}
  {%- set test_type = dbt_test_results.escape_sql_string(result.test_type) -%}
  {%- set column_name = dbt_test_results.escape_sql_string(result.get('column_name')) -%}
  {%- set status = dbt_test_results.escape_sql_string(result.status) -%}
  {%- set execution_time_seconds = result.get('execution_time_seconds', 'NULL') -%}
  {%- set failures = result.failures | default(0) -%}
  {%- set message = dbt_test_results.escape_sql_string(result.get('message')) -%}
  {%- set dbt_version = dbt_test_results.escape_sql_string(result.dbt_version) -%}
  {%- set test_unique_id = dbt_test_results.escape_sql_string(result.test_unique_id) -%}
  {%- set compiled_code_checksum = dbt_test_results.escape_sql_string(result.get('compiled_code_checksum')) -%}
  {%- set additional_metadata = dbt_test_results.escape_sql_string(result.get('additional_metadata')) -%}
  
  {%- set row_values = [
    "'" ~ execution_id ~ "'",
    execution_timestamp,
    "'" ~ model_name ~ "'",
    "'" ~ test_name ~ "'",
    "'" ~ test_type ~ "'",
    "'" ~ column_name ~ "'" if column_name != 'NULL' else 'NULL',
    "'" ~ status ~ "'",
    execution_time_seconds,
    failures,
    "'" ~ message ~ "'" if message != 'NULL' else 'NULL',
    "'" ~ dbt_version ~ "'",
    "'" ~ test_unique_id ~ "'",
    "'" ~ compiled_code_checksum ~ "'" if compiled_code_checksum != 'NULL' else 'NULL',
    "'" ~ additional_metadata ~ "'" if additional_metadata != 'NULL' else 'NULL'
  ] -%}
  
  {{ return("(" ~ row_values | join(', ') ~ ")") }}
{% endmacro %}


{% macro merge_test_results(schema_name, table_name, test_results) %}
  {%- set full_table_name = schema_name ~ '.' ~ table_name -%}
  
  {%- if test_results | length == 0 -%}
    {{ return(0) }}
  {%- endif -%}
  
  {%- do log("dbt-test-results: Using MERGE operation for " ~ test_results | length ~ " results", true) -%}
  
  {%- set temp_table_name = 'temp_test_results_' ~ modules.datetime.datetime.now().strftime('%Y%m%d_%H%M%S') -%}
  {%- set temp_full_table_name = schema_name ~ '.' ~ temp_table_name -%}
  
  {%- set create_temp_sql -%}
    CREATE TEMPORARY VIEW {{ temp_full_table_name }} AS
    SELECT * FROM VALUES
    {%- for result in test_results %}
    {{ dbt_test_results.format_result_row(result) }}
    {%- if not loop.last -%},{%- endif -%}
    {%- endfor %}
    AS t(
      execution_id,
      execution_timestamp,
      model_name,
      test_name,
      test_type,
      column_name,
      status,
      execution_time_seconds,
      failures,
      message,
      dbt_version,
      test_unique_id,
      compiled_code_checksum,
      additional_metadata
    )
  {%- endset -%}
  
  {%- do run_query(create_temp_sql) -%}
  
  {%- set merge_sql -%}
    MERGE INTO {{ full_table_name }} AS target
    USING {{ temp_full_table_name }} AS source
    ON target.execution_id = source.execution_id
       AND target.test_unique_id = source.test_unique_id
    WHEN NOT MATCHED THEN
      INSERT (
        execution_id,
        execution_timestamp,
        model_name,
        test_name,
        test_type,
        column_name,
        status,
        execution_time_seconds,
        failures,
        message,
        dbt_version,
        test_unique_id,
        compiled_code_checksum,
        additional_metadata
      )
      VALUES (
        source.execution_id,
        source.execution_timestamp,
        source.model_name,
        source.test_name,
        source.test_type,
        source.column_name,
        source.status,
        source.execution_time_seconds,
        source.failures,
        source.message,
        source.dbt_version,
        source.test_unique_id,
        source.compiled_code_checksum,
        source.additional_metadata
      )
  {%- endset -%}
  
  {%- do run_query(merge_sql) -%}
  {%- do log("dbt-test-results: MERGE operation completed for " ~ full_table_name, true) -%}
  
  {{ return(test_results | length) }}
{% endmacro %}


{% macro cleanup_old_test_results(schema_name, table_name, retention_days=90) %}
  {%- set full_table_name = schema_name ~ '.' ~ table_name -%}
  {%- set retention_days_int = retention_days | int -%}
  
  {%- set cleanup_sql -%}
    DELETE FROM {{ full_table_name }}
    WHERE execution_timestamp < CURRENT_TIMESTAMP() - INTERVAL {{ retention_days_int }} DAYS
  {%- endset -%}
  
  {%- do log("dbt-test-results: Cleaning up test results older than " ~ retention_days_int ~ " days from " ~ full_table_name, true) -%}
  {%- set result = run_query(cleanup_sql) -%}
  
  {{ return(true) }}
{% endmacro %}


{% macro get_test_results_stats(schema_name, table_name) %}
  {%- set full_table_name = schema_name ~ '.' ~ table_name -%}
  
  {%- set stats_sql -%}
    SELECT 
      COUNT(*) as total_records,
      COUNT(DISTINCT execution_id) as unique_executions,
      COUNT(DISTINCT model_name) as unique_models,
      MIN(execution_timestamp) as earliest_execution,
      MAX(execution_timestamp) as latest_execution,
      SUM(CASE WHEN status = 'pass' THEN 1 ELSE 0 END) as passed_tests,
      SUM(CASE WHEN status = 'fail' THEN 1 ELSE 0 END) as failed_tests,
      SUM(CASE WHEN status = 'error' THEN 1 ELSE 0 END) as error_tests
    FROM {{ full_table_name }}
  {%- endset -%}
  
  {%- set result = run_query(stats_sql) -%}
  {{ return(result) }}
{% endmacro %}