{#
  Simple test results logger that directly processes the dbt results object.
  This approach is more reliable than the complex model-matching logic.
#}

{% macro log_all_test_results(results) %}
  {%- if not execute -%}
    {{ return('') }}
  {%- endif -%}
  
  {%- set config = var('dbt_test_results', {}) -%}
  {%- if not config.get('enabled', true) -%}
    {{ return('') }}
  {%- endif -%}
  
  {%- if not results -%}
    {%- do dbt_test_results.log_message('warn', 'No results object available') -%}
    {{ return('') }}
  {%- endif -%}
  
  {%- set test_results = [] -%}
  {%- set invocation_id = invocation_id | default(run_started_at | string | replace(' ', '_') | replace(':', '-')) -%}
  
  {%- for result in results -%}
    {%- if result.node.resource_type == 'test' -%}
      {%- set test_result = {
        'invocation_id': invocation_id,
        'test_execution_id': result.unique_id | replace('.', '_'),
        'test_name': result.node.name,
        'test_unique_id': result.unique_id,
        'model_name': result.node.attached_node | default('unknown'),
        'test_type': result.node.test_metadata.name | default('custom'),
        'status': result.status,
        'failures': result.failures | default(0) | int,
        'execution_time_seconds': result.execution_time | default(0) | float,
        'execution_time_ms': (result.execution_time | default(0) | float * 1000) | round | int,
        'test_executed_at': 'CURRENT_TIMESTAMP()',
        'run_started_at': run_started_at | string,
        'target_name': target.name,
        'profile_name': target.profile_name,
        'message': result.message | default('') | string | replace("'", "''")
      } -%}
      {%- do test_results.append(test_result) -%}
    {%- endif -%}
  {%- endfor -%}
  
  {%- if test_results | length > 0 -%}
    {%- do dbt_test_results.log_message('info', 'Found ' ~ test_results | length ~ ' test results to store') -%}
    
    {%- set schema_name = config.get('absolute_schema', 'test_results') -%}
    {%- set table_name = config.get('global_table_name', 'all_test_results') -%}
    
    {%- do dbt_test_results.log_message('info', 'Storing results in ' ~ schema_name ~ '.' ~ table_name) -%}
    
    {%- set create_schema_sql -%}
      CREATE SCHEMA IF NOT EXISTS {{ schema_name }}
    {%- endset -%}
    
    {%- do run_query(create_schema_sql) -%}
    
    {%- set create_table_sql -%}
      CREATE TABLE IF NOT EXISTS {{ schema_name }}.{{ table_name }} (
        invocation_id STRING,
        test_execution_id STRING,
        test_name STRING,
        test_unique_id STRING,
        model_name STRING,
        test_type STRING,
        status STRING,
        failures INT,
        execution_time_seconds DOUBLE,
        execution_time_ms BIGINT,
        test_executed_at TIMESTAMP,
        run_started_at STRING,
        target_name STRING,
        profile_name STRING,
        message STRING
      ) USING DELTA
      TBLPROPERTIES (
        'delta.autoOptimize.optimizeWrite' = 'true',
        'delta.autoOptimize.autoCompact' = 'true'
      )
    {%- endset -%}
    
    {%- do run_query(create_table_sql) -%}
    
    {%- set insert_sql -%}
      INSERT INTO {{ schema_name }}.{{ table_name }} (
        invocation_id,
        test_execution_id,
        test_name,
        test_unique_id,
        model_name,
        test_type,
        status,
        failures,
        execution_time_seconds,
        execution_time_ms,
        test_executed_at,
        run_started_at,
        target_name,
        profile_name,
        message
      )
      SELECT
        invocation_id,
        test_execution_id,
        test_name,
        test_unique_id,
        model_name,
        test_type,
        status,
        failures,
        execution_time_seconds,
        execution_time_ms,
        CAST(test_executed_at AS TIMESTAMP),
        run_started_at,
        target_name,
        profile_name,
        message
      FROM (
        {%- for result in test_results %}
          SELECT
            '{{ result.invocation_id }}' AS invocation_id,
            '{{ result.test_execution_id }}' AS test_execution_id,
            '{{ result.test_name }}' AS test_name,
            '{{ result.test_unique_id }}' AS test_unique_id,
            '{{ result.model_name }}' AS model_name,
            '{{ result.test_type }}' AS test_type,
            '{{ result.status }}' AS status,
            {{ result.failures }} AS failures,
            {{ result.execution_time_seconds }} AS execution_time_seconds,
            {{ result.execution_time_ms }} AS execution_time_ms,
            {{ result.test_executed_at }} AS test_executed_at,
            '{{ result.run_started_at }}' AS run_started_at,
            '{{ result.target_name }}' AS target_name,
            '{{ result.profile_name }}' AS profile_name,
            '{{ result.message }}' AS message
          {%- if not loop.last %} UNION ALL {%- endif %}
        {%- endfor %}
      ) AS test_data
    {%- endset -%}
    
    {%- do run_query(insert_sql) -%}
    {%- do dbt_test_results.log_message('info', 'Successfully stored ' ~ test_results | length ~ ' test results') -%}
  {%- else -%}
    {%- do dbt_test_results.log_message('info', 'No test results found to store') -%}
  {%- endif -%}
  
  {{ return('SELECT 1 as simple_logger_complete') }}
{% endmacro %}