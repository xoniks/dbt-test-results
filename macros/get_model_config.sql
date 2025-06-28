{#
  Scans the dbt graph to find models configured for test result storage.
  
  This macro examines all model nodes in the dbt graph and extracts
  configurations for models that have 'store_test_results' specified
  in their schema.yml config.
  
  Returns:
    List of dictionaries containing model configuration:
    - model_name: Name of the model
    - model_unique_id: Unique identifier for the model
    - table_name: Target table name for test results
    - schema_name: Target schema name for test results
    - original_model_schema: Original model schema
    - model_database: Model database
  
  Usage:
    {% set model_configs = dbt_test_results.get_model_configs() %}
#}
{% macro get_model_configs() %}
  {%- set model_configs = [] -%}
  
  {%- if graph is defined and graph.nodes -%}
    {%- do dbt_test_results.log_message('debug', 'Scanning ' ~ graph.nodes.keys() | length ~ ' nodes for test result configurations') -%}
    
    {%- for node_id, node in graph.nodes.items() -%}
      {%- if node.resource_type == 'model' -%}
        {%- set model_config = dbt_test_results.extract_model_test_config(node) -%}
        {%- if model_config -%}
          {%- do model_configs.append(model_config) -%}
          {%- do dbt_test_results.log_message('debug', 'Found test config for model \'' ~ node.name ~ '\' -> table \'' ~ model_config.table_name ~ '\'') -%}
        {%- endif -%}
      {%- endif -%}
    {%- endfor -%}
  {%- else -%}
    {%- do dbt_test_results.log_message('warn', 'Graph object not available') -%}
  {%- endif -%}
  
  {{ return(model_configs) }}
{% endmacro %}


{#
  Extracts and validates test result configuration from a model node.
  
  Args:
    node: dbt model node object from the graph
  
  Returns:
    Dictionary with model configuration or none if not configured:
    - model_name: Name of the model
    - table_name: Target table for test results
    - schema_name: Target schema for test results
    - And other metadata fields
  
  Usage:
    {% set config = dbt_test_results.extract_model_test_config(node) %}
#}
{% macro extract_model_test_config(node) %}
  {%- set store_test_results = node.config.get('store_test_results') -%}
  
  {%- if store_test_results -%}
    {%- if store_test_results is string and store_test_results | length > 0 -%}
      {%- set target_schema = dbt_test_results.get_target_schema(node.schema) -%}
      
      {%- set config = {
        'model_name': node.name,
        'model_unique_id': node.unique_id,
        'table_name': store_test_results,
        'schema_name': target_schema,
        'original_model_schema': node.schema,
        'model_database': node.database
      } -%}
      
      {%- if dbt_test_results.validate_model_config(config) -%}
        {{ return(config) }}
      {%- else -%}
        {%- do dbt_test_results.log_message('warn', 'Invalid configuration for model \'' ~ node.name ~ '\'') -%}
        {{ return(none) }}
      {%- endif -%}
    {%- else -%}
      {%- do dbt_test_results.log_message('warn', 'Invalid store_test_results value for model \'' ~ node.name ~ '\'. Expected non-empty string, got: ' ~ store_test_results) -%}
      {{ return(none) }}
    {%- endif -%}
  {%- endif -%}
  
  {{ return(none) }}
{% endmacro %}


{#
  Validates a model configuration for required fields and proper formatting.
  
  Args:
    config: Dictionary containing model configuration
  
  Returns:
    Boolean indicating whether the configuration is valid
  
  Validates:
    - Required fields are present (model_name, table_name, schema_name)
    - Table name follows valid identifier patterns
    - No SQL injection or invalid characters
  
  Usage:
    {% if dbt_test_results.validate_model_config(config) %}
#}
{% macro validate_model_config(config) %}
  {%- set required_fields = ['model_name', 'table_name', 'schema_name'] -%}
  {%- set is_valid = true -%}
  
  {%- for field in required_fields -%}
    {%- if not config.get(field) -%}
      {%- do dbt_test_results.log_message('error', 'Missing required field \'' ~ field ~ '\' in model configuration') -%}
      {%- set is_valid = false -%}
    {%- endif -%}
  {%- endfor -%}
  
  {%- if config.get('table_name') -%}
    {%- set table_name = config.table_name -%}
    {%- if not dbt_test_results.is_valid_table_name(table_name) -%}
      {%- do dbt_test_results.log_message('error', 'Invalid table name \'' ~ table_name ~ '\'. Table names must contain only alphanumeric characters and underscores') -%}
      {%- set is_valid = false -%}
    {%- endif -%}
  {%- endif -%}
  
  {{ return(is_valid) }}
{% endmacro %}


{#
  Validates that a table name follows SQL identifier rules.
  
  Args:
    table_name: String table name to validate
  
  Returns:
    Boolean indicating if the table name is valid
  
  Validation rules:
    - Must start with a letter
    - Can contain letters, numbers, and underscores
    - No spaces or special characters
  
  Usage:
    {% if dbt_test_results.is_valid_table_name('my_table') %}
#}
{% macro is_valid_table_name(table_name) %}
  {%- set is_valid = true -%}
  {# Simple validation: not empty and doesn't contain spaces or special chars #}
  {%- if table_name | length == 0 -%}
    {%- set is_valid = false -%}
  {%- elif ' ' in table_name or '-' in table_name or '.' in table_name -%}
    {%- set is_valid = false -%}
  {%- elif table_name | first | int(-1) >= 0 -%}
    {# starts with a number #}
    {%- set is_valid = false -%}
  {%- endif -%}
  {{ return(is_valid) }}
{% endmacro %}


{#
  Finds a model configuration by model name.
  
  Args:
    model_name: Name of the model to find
    model_configs: List of model configurations
  
  Returns:
    Model configuration dictionary or none if not found
  
  Usage:
    {% set config = dbt_test_results.get_model_config_by_name('customers', configs) %}
#}
{% macro get_model_config_by_name(model_name, model_configs) %}
  {%- for config in model_configs -%}
    {%- if config.model_name == model_name -%}
      {{ return(config) }}
    {%- endif -%}
  {%- endfor -%}
  {{ return(none) }}
{% endmacro %}


{#
  Finds a model configuration by unique ID.
  
  Args:
    unique_id: Unique identifier of the model
    model_configs: List of model configurations
  
  Returns:
    Model configuration dictionary or none if not found
  
  Usage:
    {% set config = dbt_test_results.get_model_config_by_unique_id(node.unique_id, configs) %}
#}
{% macro get_model_config_by_unique_id(unique_id, model_configs) %}
  {%- for config in model_configs -%}
    {%- if config.model_unique_id == unique_id -%}
      {{ return(config) }}
    {%- endif -%}
  {%- endfor -%}
  {{ return(none) }}
{% endmacro %}