{#
  Main entry point for storing dbt test results.
  
  This macro is called from the on-run-end hook to automatically capture
  and store test results for models configured with 'store_test_results'.
  
  The macro:
  1. Validates package configuration
  2. Scans for models with test result storage enabled
  3. Processes test results from the dbt results object
  4. Creates necessary tables and schemas
  5. Stores test results in batches for performance
  
  Returns:
    None - Performs side effects by creating tables and inserting data
  
  Usage:
    Called automatically via on-run-end hook:
    on-run-end:
      - "{% if execute %}{{ dbt_test_results.store_test_results() }}{% endif %}"
#}
{% macro store_test_results() %}
  {%- if dbt_test_results.get_config('enabled', true) -%}
    {%- do dbt_test_results.log_configuration_summary() -%}
    
    {%- set config_valid = dbt_test_results.validate_configuration() -%}
    {%- set fail_on_error = dbt_test_results.get_config('fail_on_error', false) -%}
    {%- if not config_valid -%}
      {%- if fail_on_error -%}
        {%- do dbt_test_results.log_message('error', 'Configuration validation failed, aborting test result processing') -%}
        {{ return('') }}
      {%- else -%}
        {%- do dbt_test_results.log_message('warn', 'Configuration validation failed, but continuing due to fail_on_error: false') -%}
      {%- endif -%}
    {%- endif -%}
    
    {%- if results is defined and results -%}
      {%- do dbt_test_results.log_message('info', 'Starting test result processing...') -%}
      
      {%- set model_configs = dbt_test_results.get_model_configs() -%}
      
      {%- if model_configs | length > 0 -%}
        {%- do dbt_test_results.log_message('info', 'Found ' ~ model_configs | length ~ ' models with test result storage configured') -%}
        
        {# Check memory constraints for large result sets #}
        {%- set total_test_count = results | selectattr('node.resource_type', 'equalto', 'test') | list | length -%}
        {%- set memory_limit = dbt_test_results.get_config('memory_limit_mb', 2048) | int -%}
        {%- set estimated_memory_mb = ((total_test_count * 1024) / 1024 / 1024) | int -%}
        
        {%- if total_test_count > 5000 -%}
          {%- do dbt_test_results.log_message('info', 'Large test suite detected (' ~ total_test_count ~ ' tests). Estimated memory usage: ' ~ estimated_memory_mb ~ 'MB') -%}
          {%- if estimated_memory_mb > memory_limit -%}
            {%- do dbt_test_results.log_message('warn', 'Estimated memory usage (' ~ estimated_memory_mb ~ 'MB) exceeds limit (' ~ memory_limit ~ 'MB). Consider reducing batch_size or enable_parallel_processing: false') -%}
          {%- endif -%}
        {%- endif -%}
        
        {%- set test_results = dbt_test_results.parse_test_results(results, model_configs) -%}
        
        {%- if test_results | length > 0 -%}
          {%- do dbt_test_results.log_message('info', 'Processing ' ~ test_results | length ~ ' test result batches') -%}
          
          {%- for result_batch in test_results -%}
            {%- set table_name = result_batch.table_name -%}
            {%- set schema_name = result_batch.schema_name -%}
            {%- set results_data = result_batch.results -%}
            
            {%- if results_data | length > 0 -%}
              {%- do dbt_test_results.log_message('info', 'Storing ' ~ results_data | length ~ ' results in ' ~ schema_name ~ '.' ~ table_name) -%}
              
              {%- set table_ready = dbt_test_results.create_or_validate_table(schema_name, table_name) -%}
              
              {%- if table_ready -%}
                {%- set inserted_count = dbt_test_results.insert_test_results(schema_name, table_name, results_data) -%}
                {%- do dbt_test_results.log_message('info', 'Successfully stored ' ~ inserted_count ~ ' results in ' ~ schema_name ~ '.' ~ table_name) -%}
              {%- else -%}
                {%- do dbt_test_results.handle_error('Failed to prepare table ' ~ schema_name ~ '.' ~ table_name, 'table_preparation') -%}
              {%- endif -%}
            {%- endif -%}
          {%- endfor -%}
        {%- else -%}
          {%- do dbt_test_results.log_message('info', 'No test results found to store') -%}
        {%- endif -%}
      {%- else -%}
        {%- do dbt_test_results.log_message('info', 'No models configured for test result storage') -%}
      {%- endif -%}
    {%- else -%}
      {%- do dbt_test_results.log_message('warn', 'No results object available') -%}
    {%- endif -%}
  {%- else -%}
    {%- do dbt_test_results.log_message('info', 'Package disabled via configuration') -%}
  {%- endif -%}
  
  {# Always return valid SQL #}
  {{ return('SELECT 1 as dbt_test_results_complete') }}
{% endmacro %}


