{#
  Parses dbt test results and prepares them for storage.
  
  This macro processes the dbt results object to extract test metadata
  and format it for insertion into test result tables.
  
  Args:
    results: dbt results object containing test execution results
    model_configs: List of model configurations for test storage
  
  Returns:
    List of grouped results by target table:
    - table_name: Target table for results
    - schema_name: Target schema for results  
    - results: List of formatted test result records
  
  Usage:
    {% set test_results = dbt_test_results.parse_test_results(results, configs) %}
#}
{% macro parse_test_results(results, model_configs) %}
  {%- set parsed_results = [] -%}
  {%- set execution_id = dbt_test_results.generate_execution_id() -%}
  {%- set execution_time = dbt_test_results.get_current_timestamp() -%}
  {%- set dbt_version = dbt_test_results.get_dbt_version() -%}
  
  {%- do dbt_test_results.log_message('debug', 'Parsing results with execution ID: ' ~ execution_id) -%}
  
  {%- for result in results -%}
    {%- if result.node.resource_type == 'test' -%}
      {%- if dbt_test_results.should_process_test(result.node, result) -%}
        {%- set test_result = dbt_test_results.process_test_result(result, model_configs, execution_id, execution_time, dbt_version) -%}
        {%- if test_result -%}
          {%- do parsed_results.append(test_result) -%}
        {%- endif -%}
      {%- endif -%}
    {%- endif -%}
  {%- endfor -%}
  
  {%- set grouped_results = dbt_test_results.group_results_by_table(parsed_results) -%}
  
  {{ return(grouped_results) }}
{% endmacro %}


{#
  Processes a single test result into the storage format.
  
  Args:
    result: Single test result from dbt results object
    model_configs: List of model configurations
    execution_id: Unique execution identifier
    execution_timestamp: Timestamp of execution
    dbt_version: Version of dbt being used
  
  Returns:
    Dictionary with formatted test result data or none if not applicable:
    - execution_id: Unique execution ID
    - model_name: Name of tested model
    - test_name: Name of the test
    - test_type: Type of test (unique, not_null, etc.)
    - status: Test result status
    - And other metadata fields
  
  Usage:
    {% set formatted_result = dbt_test_results.process_test_result(result, configs, id, timestamp, version) %}
#}
{% macro process_test_result(result, model_configs, execution_id, execution_timestamp, dbt_version) %}
  {%- set test_node = result.node -%}
  {%- set test_name = test_node.name -%}
  {%- set test_status = result.status | lower -%}
  {%- set test_failures = result.failures | default(0) -%}
  
  {%- set target_model = dbt_test_results.get_test_target_model(test_node) -%}
  {%- if not target_model -%}
    {%- do dbt_test_results.log_message('warn', 'Could not determine target model for test \'' ~ test_name ~ '\'') -%}
    {{ return(none) }}
  {%- endif -%}
  
  {%- set model_config = dbt_test_results.get_model_config_by_name(target_model, model_configs) -%}
  {%- if not model_config -%}
    {{ return(none) }}
  {%- endif -%}
  
  {%- set test_type = dbt_test_results.extract_test_type(test_node) -%}
  {%- set additional_metadata = dbt_test_results.build_test_metadata(test_node, result) -%}
  
  {%- set column_name = dbt_test_results.extract_column_name(test_node) -%}
  {%- set execution_time_seconds = dbt_test_results.calculate_execution_time(result) -%}
  {%- set message = dbt_test_results.extract_test_message(result) -%}

  {%- set parsed_result = {
    'execution_id': execution_id,
    'execution_timestamp': execution_timestamp,
    'model_name': target_model,
    'test_name': test_name,
    'test_type': test_type,
    'column_name': column_name,
    'status': test_status,
    'execution_time_seconds': execution_time_seconds,
    'failures': test_failures,
    'message': message,
    'dbt_version': dbt_version,
    'test_unique_id': test_node.unique_id,
    'compiled_code_checksum': test_node.checksum.name if test_node.checksum else none,
    'additional_metadata': additional_metadata,
    'table_name': model_config.table_name,
    'schema_name': model_config.schema_name
  } -%}
  
  {%- do dbt_test_results.log_message('debug', 'Processed test \'' ~ test_name ~ '\' for model \'' ~ target_model ~ '\' - Status: ' ~ test_status) -%}
  
  {{ return(parsed_result) }}
{% endmacro %}


{#
  Determines which model a test is targeting.
  
  This macro analyzes test node dependencies and metadata to identify
  the target model for the test. Uses multiple strategies for robustness.
  
  Args:
    test_node: dbt test node object
  
  Returns:
    String model name or none if cannot be determined
  
  Strategies used:
    1. Check test dependencies for model references
    2. Extract from test metadata kwargs
    3. Parse test name for model name patterns
  
  Usage:
    {% set target_model = dbt_test_results.get_test_target_model(test_node) %}
#}
{% macro get_test_target_model(test_node) %}
  {%- if test_node.depends_on and test_node.depends_on.nodes -%}
    {%- for dependency in test_node.depends_on.nodes -%}
      {%- if dependency.startswith('model.') -%}
        {%- set model_parts = dependency.split('.') -%}
        {%- if model_parts | length >= 3 -%}
          {{ return(model_parts[2]) }}
        {%- endif -%}
      {%- endif -%}
    {%- endfor -%}
  {%- endif -%}
  
  {%- if test_node.test_metadata and test_node.test_metadata.kwargs -%}
    {%- set kwargs = test_node.test_metadata.kwargs -%}
    {%- if kwargs.model -%}
      {{ return(kwargs.model) }}
    {%- endif -%}
  {%- endif -%}
  
  {%- set test_name_parts = test_node.name.split('_') -%}
  {%- if test_name_parts | length > 1 -%}
    {%- for i in range(test_name_parts | length - 1, 0, -1) -%}
      {%- set potential_model = test_name_parts[1:i] | join('_') -%}
      {%- if potential_model | length > 0 -%}
        {{ return(potential_model) }}
      {%- endif -%}
    {%- endfor -%}
  {%- endif -%}
  
  {{ return(none) }}
{% endmacro %}


{#
  Extracts the type of test from a test node.
  
  Args:
    test_node: dbt test node object
  
  Returns:
    String test type (unique, not_null, relationships, etc.)
  
  Detection methods:
    1. Check test_metadata.name for explicit type
    2. Parse test name for common test types
    3. Default to 'custom' for unknown types
  
  Usage:
    {% set test_type = dbt_test_results.extract_test_type(test_node) %}
#}
{% macro extract_test_type(test_node) %}
  {%- if test_node.test_metadata and test_node.test_metadata.name -%}
    {{ return(test_node.test_metadata.name) }}
  {%- endif -%}
  
  {%- set test_name = test_node.name | lower -%}
  {%- set common_tests = ['unique', 'not_null', 'accepted_values', 'relationships'] -%}
  
  {%- for test_type in common_tests -%}
    {%- if test_type in test_name -%}
      {{ return(test_type) }}
    {%- endif -%}
  {%- endfor -%}
  
  {{ return('custom') }}
{% endmacro %}


{#
  Builds additional metadata JSON for test results.
  
  Args:
    test_node: dbt test node object
    result: Test execution result
  
  Returns:
    JSON string with additional test metadata:
    - test_kwargs: Test configuration parameters
    - test_namespace: Test namespace
    - execution_time_ms: Execution time in milliseconds
    - message: Test failure message
    - node_unique_id: Unique node identifier
    - compiled_code_checksum: SQL checksum
  
  Usage:
    {% set metadata = dbt_test_results.build_test_metadata(node, result) %}
#}
{% macro build_test_metadata(test_node, result) %}
  {%- set metadata = {} -%}
  
  {# Simplified metadata to avoid serialization issues with complex objects #}
  {%- if test_node.test_metadata -%}
    {%- set _ = metadata.update({'test_namespace': test_node.test_metadata.namespace | string if test_node.test_metadata.namespace else 'default'}) -%}
  {%- endif -%}
  
  {%- set _ = metadata.update({'node_unique_id': test_node.unique_id}) -%}
  {%- set _ = metadata.update({'compiled_code_checksum': test_node.checksum.name if test_node.checksum else 'unknown'}) -%}
  
  {%- set metadata_json = metadata | tojson -%}
  {%- set escaped_metadata = metadata_json | replace("'", "''") -%}
  
  {{ return(escaped_metadata) }}
{% endmacro %}


{#
  Groups test results by target table for batch processing.
  
  Args:
    parsed_results: List of parsed test result records
  
  Returns:
    List of grouped results:
    - table_name: Target table name
    - schema_name: Target schema name
    - results: List of test results for this table
  
  Usage:
    {% set grouped = dbt_test_results.group_results_by_table(results) %}
#}
{% macro group_results_by_table(parsed_results) %}
  {%- set grouped = {} -%}
  
  {%- for result in parsed_results -%}
    {%- set table_key = result.schema_name ~ '.' ~ result.table_name -%}
    
    {%- if table_key not in grouped -%}
      {%- set _ = grouped.update({table_key: {
        'table_name': result.table_name,
        'schema_name': result.schema_name,
        'results': []
      }}) -%}
    {%- endif -%}
    
    {%- set _ = grouped[table_key].results.append(result) -%}
  {%- endfor -%}
  
  {{ return(grouped.values()) }}
{% endmacro %}


{#
  Generates a unique execution ID for test runs.
  
  Returns:
    String execution ID in format: exec_YYYYMMDD_HHMMSS_NNNN
  
  Format:
    - exec: prefix
    - YYYYMMDD: date
    - HHMMSS: time
    - NNNN: random suffix for uniqueness
  
  Usage:
    {% set execution_id = dbt_test_results.generate_execution_id() %}
#}
{% macro generate_execution_id() %}
  {%- set timestamp = modules.datetime.datetime.now().strftime('%Y%m%d_%H%M%S') -%}
  {%- set random_suffix = range(1000, 9999) | random -%}
  {{ return('exec_' ~ timestamp ~ '_' ~ random_suffix) }}
{% endmacro %}


{#
  Gets the current timestamp for test execution.
  
  Returns:
    String timestamp in format: YYYY-MM-DD HH:MM:SS
  
  Usage:
    {% set timestamp = dbt_test_results.get_current_timestamp() %}
#}
{% macro get_current_timestamp() %}
  {{ return(modules.datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')) }}
{% endmacro %}


{% macro extract_column_name(test_node) %}
  {%- if test_node.test_metadata and test_node.test_metadata.kwargs -%}
    {%- set kwargs = test_node.test_metadata.kwargs -%}
    {%- if kwargs.column_name -%}
      {{ return(kwargs.column_name) }}
    {%- endif -%}
  {%- endif -%}
  
  {%- set test_name = test_node.name | lower -%}
  {%- set name_parts = test_name.split('_') -%}
  
  {%- if name_parts | length > 2 -%}
    {%- for i in range(name_parts | length - 1, 1, -1) -%}
      {%- set potential_column = name_parts[i] -%}
      {%- if potential_column not in ['unique', 'not', 'null', 'accepted', 'values', 'relationships'] -%}
        {{ return(potential_column) }}
      {%- endif -%}
    {%- endfor -%}
  {%- endif -%}
  
  {{ return(none) }}
{% endmacro %}


{% macro calculate_execution_time(result) %}
  {%- if result.execution_time -%}
    {{ return(result.execution_time) }}
  {%- elif result.timing and result.timing | length > 0 -%}
    {%- set timing_info = result.timing[-1] -%}
    {%- if timing_info.started_at and timing_info.completed_at -%}
      {# Simple fallback - use 0 if we can't calculate timing #}
      {{ return(0.0) }}
    {%- endif -%}
  {%- endif -%}
  
  {{ return(0.0) }}
{% endmacro %}


{% macro extract_test_message(result) %}
  {%- if result.message -%}
    {%- set clean_message = result.message | replace('\n', ' ') | replace('\r', '') | truncate(1000) -%}
    {{ return(clean_message) }}
  {%- endif -%}
  
  {{ return(none) }}
{% endmacro %}


{#
  Gets the current dbt version.
  
  Returns:
    String dbt version or 'unknown' if not available
  
  Usage:
    {% set version = dbt_test_results.get_dbt_version() %}
#}
{% macro get_dbt_version() %}
  {%- if dbt_version -%}
    {{ return(dbt_version) }}
  {%- else -%}
    {{ return('unknown') }}
  {%- endif -%}
{% endmacro %}


{#
  Escapes a string value for safe SQL insertion.
  
  Args:
    value: Value to escape (string, number, or none)
  
  Returns:
    Escaped string safe for SQL insertion:
    - Handles single quotes, backslashes
    - Converts none to NULL
    - Converts non-strings to strings
  
  Usage:
    {% set safe_value = dbt_test_results.escape_sql_string(user_input) %}
#}
{% macro escape_sql_string(value) %}
  {%- if value is none -%}
    {{ return('NULL') }}
  {%- elif value is string -%}
    {%- set escaped = value | replace("'", "''") | replace("\\", "\\\\") -%}
    {{ return(escaped) }}
  {%- else -%}
    {{ return(value | string) }}
  {%- endif -%}
{% endmacro %}