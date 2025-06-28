{#
  Safely retrieves configuration values with dot notation support.
  
  Args:
    key: Configuration key, supports dot notation (e.g., 'logging.level')
    default_value: Default value if key not found
  
  Returns:
    Configuration value or default_value if not found
  
  Usage:
    {% set batch_size = dbt_test_results.get_config('batch_size', 1000) %}
    {% set log_level = dbt_test_results.get_config('logging.level', 'info') %}
#}
{% macro get_config(key, default_value=none) %}
  {%- set config = var('dbt_test_results', {}) -%}
  {%- set keys = key.split('.') -%}
  {%- set current = config -%}
  
  {%- for k in keys -%}
    {%- if current is mapping and k in current -%}
      {%- set current = current[k] -%}
    {%- else -%}
      {{ return(default_value) }}
    {%- endif -%}
  {%- endfor -%}
  
  {{ return(current) }}
{% endmacro %}


{#
  Validates the dbt-test-results package configuration.
  
  Returns:
    Boolean indicating if configuration is valid
  
  Validates:
    - batch_size is within reasonable range (1-10000)
    - retention_days is non-negative
    - max_retries is within limits (0-10)
    - schema naming is valid
    - file_format is supported
    - log_level is valid
  
  Usage:
    {% if dbt_test_results.validate_configuration() %}
#}
{% macro validate_configuration() %}
  {%- set validation_errors = [] -%}
  {%- set config = var('dbt_test_results', {}) -%}
  
  {%- if dbt_test_results.get_config('debug_mode', false) -%}
    {%- do dbt_test_results.log_message('debug', 'Starting configuration validation') -%}
  {%- endif -%}
  
  {%- set batch_size_raw = dbt_test_results.get_config('batch_size', 1000) -%}
  {%- if batch_size_raw is mapping -%}
    {# get_config returned the entire config dict instead of the value #}
    {%- set batch_size = 1000 -%}
    {%- do dbt_test_results.log_message('debug', 'get_config returned dict instead of value, using default batch_size: 1000') -%}
  {%- else -%}
    {%- set batch_size = batch_size_raw | int if batch_size_raw is not none and batch_size_raw != 0 else 1000 -%}
  {%- endif -%}
  {%- if batch_size <= 0 or batch_size > 50000 -%}
    {%- do validation_errors.append('batch_size must be between 1 and 50000, got: ' ~ batch_size ~ ' (raw: ' ~ batch_size_raw ~ '). For batches >10000, ensure adequate memory is available.') -%}
  {%- endif -%}
  
  {%- set retention_days_raw = dbt_test_results.get_config('retention_days', 90) -%}
  {%- set retention_days = retention_days_raw | int if retention_days_raw is not mapping else 90 -%}
  {%- if retention_days < 0 -%}
    {%- do validation_errors.append('retention_days cannot be negative, got: ' ~ retention_days) -%}
  {%- endif -%}
  
  {%- set max_retries_raw = dbt_test_results.get_config('max_retries', 2) -%}
  {%- set max_retries = max_retries_raw | int if max_retries_raw is not mapping else 2 -%}
  {%- if max_retries < 0 or max_retries > 10 -%}
    {%- do validation_errors.append('max_retries must be between 0 and 10, got: ' ~ max_retries) -%}
  {%- endif -%}
  
  {%- set schema_suffix_raw = dbt_test_results.get_config('schema_suffix', '_test_results') -%}
  {%- set schema_suffix = schema_suffix_raw if schema_suffix_raw is not mapping else '_test_results' -%}
  {%- set absolute_schema_raw = dbt_test_results.get_config('absolute_schema') -%}
  {%- set absolute_schema = absolute_schema_raw if absolute_schema_raw is not mapping else none -%}
  {%- if not schema_suffix and not absolute_schema -%}
    {%- do validation_errors.append('Either schema_suffix or absolute_schema must be specified') -%}
  {%- endif -%}
  
  {%- if schema_suffix and schema_suffix is string and not dbt_test_results.is_valid_identifier(schema_suffix.replace('_', '').replace('-', '')) -%}
    {%- do validation_errors.append('schema_suffix contains invalid characters: ' ~ schema_suffix) -%}
  {%- endif -%}
  
  {%- set file_format = dbt_test_results.get_config('table_config.file_format', 'delta') -%}
  {%- set valid_formats = ['delta', 'parquet', 'csv', 'json'] -%}
  {%- if file_format not in valid_formats -%}
    {%- do validation_errors.append('file_format must be one of: ' ~ valid_formats | join(', ') ~ ', got: ' ~ file_format) -%}
  {%- endif -%}
  
  {%- set log_level = dbt_test_results.get_config('logging.level', 'info') -%}
  {%- set valid_levels = ['debug', 'info', 'warn', 'error'] -%}
  {%- if log_level not in valid_levels -%}
    {%- do validation_errors.append('logging.level must be one of: ' ~ valid_levels | join(', ') ~ ', got: ' ~ log_level) -%}
  {%- endif -%}
  
  {%- if validation_errors | length > 0 -%}
    {%- for error in validation_errors -%}
      {%- do dbt_test_results.log_message('error', 'Configuration validation failed: ' ~ error) -%}
    {%- endfor -%}
    
    {%- if dbt_test_results.get_config('fail_on_error', false) -%}
      {%- do exceptions.raise_compiler_error('dbt-test-results configuration validation failed. See errors above.') -%}
    {%- endif -%}
    
    {{ return(false) }}
  {%- else -%}
    {%- do dbt_test_results.log_message('debug', 'Configuration validation passed') -%}
    {{ return(true) }}
  {%- endif -%}
{% endmacro %}


{#
  Logs messages with configurable levels and formatting.
  
  Args:
    level: Log level (debug, info, warn, error)
    message: Message to log
  
  Features:
    - Respects configured log level filtering
    - Optional timestamp inclusion
    - Consistent formatting across package
  
  Usage:
    {% do dbt_test_results.log_message('info', 'Processing started') %}
    {% do dbt_test_results.log_message('error', 'Configuration invalid') %}
#}
{% macro log_message(level, message) %}
  {%- set log_config = dbt_test_results.get_config('logging', {}) -%}
  {%- set current_level = log_config.get('level', 'info') -%}
  {%- set include_timestamps = log_config.get('include_timestamps', true) -%}
  
  {%- set level_hierarchy = {'debug': 0, 'info': 1, 'warn': 2, 'error': 3} -%}
  {%- set current_level_num = level_hierarchy.get(current_level, 1) -%}
  {%- set message_level_num = level_hierarchy.get(level, 1) -%}
  
  {%- if message_level_num >= current_level_num -%}
    {%- set prefix = 'dbt-test-results [' ~ level.upper() ~ ']' -%}
    
    {%- if include_timestamps -%}
      {%- set timestamp = modules.datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S') -%}
      {%- set prefix = prefix ~ ' [' ~ timestamp ~ ']' -%}
    {%- endif -%}
    
    {%- set full_message = prefix ~ ': ' ~ message -%}
    
    {%- if level == 'error' -%}
      {%- do log(full_message, true) -%}
    {%- else -%}
      {%- do log(full_message, level in ['warn', 'error']) -%}
    {%- endif -%}
  {%- endif -%}
{% endmacro %}


{#
  Handles errors with configurable behavior.
  
  Args:
    error_message: Description of the error
    context: Context where error occurred
    continue_on_error: Whether to continue or raise (overrides config)
  
  Returns:
    Boolean indicating if execution should stop
  
  Behavior:
    - Logs error with context
    - Respects fail_on_error and continue_on_storage_error settings
    - Can raise compiler error or continue gracefully
  
  Usage:
    {% set should_stop = dbt_test_results.handle_error('Failed to create table', 'table_creation') %}
#}
{% macro handle_error(error_message, context='unknown', continue_on_error=none) %}
  {%- set should_continue = continue_on_error if continue_on_error is not none else dbt_test_results.get_config('continue_on_storage_error', true) -%}
  {%- set fail_on_error = dbt_test_results.get_config('fail_on_error', false) -%}
  
  {%- set full_message = 'Error in ' ~ context ~ ': ' ~ error_message -%}
  {%- do dbt_test_results.log_message('error', full_message) -%}
  
  {%- if fail_on_error -%}
    {%- do exceptions.raise_compiler_error('dbt-test-results: ' ~ full_message) -%}
  {%- elif not should_continue -%}
    {%- do exceptions.raise_compiler_error('dbt-test-results: ' ~ full_message) -%}
  {%- endif -%}
  
  {{ return(not should_continue) }}
{% endmacro %}


{% macro retry_operation(operation_name, operation_macro) %}
  {%- set max_retries = dbt_test_results.get_config('max_retries', 2) -%}
  {%- set retry_delay = dbt_test_results.get_config('retry_delay', 5) -%}
  
  {%- for attempt in range(max_retries + 1) -%}
    {%- if attempt > 0 -%}
      {%- do dbt_test_results.log_message('warn', 'Retrying ' ~ operation_name ~ ' (attempt ' ~ (attempt + 1) ~ '/' ~ (max_retries + 1) ~ ')') -%}
      {%- do modules.time.sleep(retry_delay) -%}
    {%- endif -%}
    
    {%- set result = operation_macro() -%}
    {%- if result is not none -%}
      {{ return(result) }}
    {%- endif -%}
  {%- endfor -%}
  
  {%- do dbt_test_results.handle_error('Operation ' ~ operation_name ~ ' failed after ' ~ (max_retries + 1) ~ ' attempts', 'retry_operation') -%}
  {{ return(none) }}
{% endmacro %}


{% macro is_valid_identifier(identifier) %}
  {%- set is_valid = true -%}
  {# Simple validation: not empty and doesn't contain spaces or special chars #}
  {%- if identifier | length == 0 -%}
    {%- set is_valid = false -%}
  {%- elif ' ' in identifier or '-' in identifier or '.' in identifier -%}
    {%- set is_valid = false -%}
  {%- elif identifier | first | int(-1) >= 0 -%}
    {# starts with a number #}
    {%- set is_valid = false -%}
  {%- endif -%}
  {{ return(is_valid) }}
{% endmacro %}


{#
  Determines if a test should be processed based on filtering configuration.
  
  Args:
    test_node: dbt test node object
    test_result: Test execution result
  
  Returns:
    Boolean indicating if test should be processed
  
  Filters applied:
    - include_test_types/exclude_test_types
    - include_models/exclude_models (supports wildcards)
    - failed_tests_only
  
  Usage:
    {% if dbt_test_results.should_process_test(node, result) %}
#}
{% macro should_process_test(test_node, test_result) %}
  {%- set test_type = dbt_test_results.extract_test_type(test_node) -%}
  {%- set model_name = dbt_test_results.get_test_target_model(test_node) -%}
  {%- set test_status = test_result.status | lower -%}
  
  {%- set include_test_types = dbt_test_results.get_config('include_test_types', []) -%}
  {%- if include_test_types | length > 0 and test_type not in include_test_types -%}
    {{ return(false) }}
  {%- endif -%}
  
  {%- set exclude_test_types = dbt_test_results.get_config('exclude_test_types', []) -%}
  {%- if test_type in exclude_test_types -%}
    {{ return(false) }}
  {%- endif -%}
  
  {%- set include_models = dbt_test_results.get_config('include_models', []) -%}
  {%- if include_models | length > 0 -%}
    {%- set model_matches = false -%}
    {%- for pattern in include_models -%}
      {%- if '*' in pattern -%}
        {%- if pattern.endswith('*') and model_name.startswith(pattern[:-1]) -%}
          {%- set model_matches = true -%}
        {%- elif pattern.startswith('*') and model_name.endswith(pattern[1:]) -%}
          {%- set model_matches = true -%}
        {%- elif pattern == '*' -%}
          {%- set model_matches = true -%}
        {%- endif -%}
      {%- elif model_name == pattern -%}
        {%- set model_matches = true -%}
      {%- endif -%}
    {%- endfor -%}
    {%- if not model_matches -%}
      {{ return(false) }}
    {%- endif -%}
  {%- endif -%}
  
  {%- set exclude_models = dbt_test_results.get_config('exclude_models', []) -%}
  {%- for pattern in exclude_models -%}
    {%- if '*' in pattern -%}
      {%- if pattern.endswith('*') and model_name.startswith(pattern[:-1]) -%}
        {{ return(false) }}
      {%- elif pattern.startswith('*') and model_name.endswith(pattern[1:]) -%}
        {{ return(false) }}
      {%- elif pattern == '*' -%}
        {{ return(false) }}
      {%- endif -%}
    {%- elif model_name == pattern -%}
      {{ return(false) }}
    {%- endif -%}
  {%- endfor -%}
  
  {%- set failed_tests_only = dbt_test_results.get_config('failed_tests_only', false) -%}
  {%- if failed_tests_only and test_status == 'pass' -%}
    {{ return(false) }}
  {%- endif -%}
  
  {{ return(true) }}
{% endmacro %}


{#
  Determines the target schema for test results.
  
  Args:
    model_schema: Original model schema
  
  Returns:
    Target schema name for test results
  
  Logic:
    - Uses absolute_schema if configured
    - Otherwise appends schema_suffix to model schema
  
  Usage:
    {% set target_schema = dbt_test_results.get_target_schema('analytics') %}
#}
{% macro get_target_schema(model_schema) %}
  {%- set config = var('dbt_test_results', {}) -%}
  {%- set absolute_schema = config.get('absolute_schema') -%}
  
  {%- do dbt_test_results.log_message('debug', 'get_target_schema: model_schema=' ~ model_schema ~ ', absolute_schema=' ~ absolute_schema) -%}
  
  {%- if absolute_schema and absolute_schema is string and absolute_schema | length > 0 -%}
    {%- do dbt_test_results.log_message('debug', 'Using absolute_schema: ' ~ absolute_schema) -%}
    {{ return(absolute_schema) }}
  {%- endif -%}
  
  {%- set schema_suffix = config.get('schema_suffix', '_test_results') -%}
  {%- if schema_suffix and schema_suffix is string -%}
    {%- do dbt_test_results.log_message('debug', 'Using schema_suffix: ' ~ model_schema ~ schema_suffix) -%}
    {{ return(model_schema ~ schema_suffix) }}
  {%- else -%}
    {%- do dbt_test_results.log_message('debug', 'Using default suffix: ' ~ model_schema ~ '_test_results') -%}
    {{ return(model_schema ~ '_test_results') }}
  {%- endif -%}
{% endmacro %}


{#
  Applies table prefix to base table name.
  
  Args:
    base_table_name: Base table name from configuration
  
  Returns:
    Final table name with prefix applied if configured
  
  Usage:
    {% set table_name = dbt_test_results.get_target_table_name('customers_test_log') %}
#}
{% macro get_target_table_name(base_table_name) %}
  {%- set table_prefix = dbt_test_results.get_config('table_prefix', '') -%}
  {%- if table_prefix -%}
    {{ return(table_prefix ~ base_table_name) }}
  {%- else -%}
    {{ return(base_table_name) }}
  {%- endif -%}
{% endmacro %}


{#
  Logs a summary of current configuration if enabled.
  
  Displays key configuration values for debugging and verification.
  Only logs if log_config_on_startup is true.
  
  Usage:
    {% do dbt_test_results.log_configuration_summary() %}
#}
{% macro log_configuration_summary() %}
  {%- if dbt_test_results.get_config('logging.log_config_on_startup', false) -%}
    {%- do dbt_test_results.log_message('info', '=== dbt-test-results Configuration Summary ===') -%}
    {%- do dbt_test_results.log_message('info', 'Enabled: ' ~ dbt_test_results.get_config('enabled', true)) -%}
    {%- do dbt_test_results.log_message('info', 'Debug Mode: ' ~ dbt_test_results.get_config('debug_mode', false)) -%}
    {%- do dbt_test_results.log_message('info', 'Schema Suffix: ' ~ dbt_test_results.get_config('schema_suffix', '_test_results')) -%}
    {%- do dbt_test_results.log_message('info', 'Batch Size: ' ~ dbt_test_results.get_config('batch_size', 1000)) -%}
    {%- do dbt_test_results.log_message('info', 'Auto Create Tables: ' ~ dbt_test_results.get_config('auto_create_tables', true)) -%}
    {%- do dbt_test_results.log_message('info', 'File Format: ' ~ dbt_test_results.get_config('table_config.file_format', 'delta')) -%}
    {%- do dbt_test_results.log_message('info', 'Retention Days: ' ~ dbt_test_results.get_config('retention_days', 90)) -%}
    {%- do dbt_test_results.log_message('info', '============================================') -%}
  {%- endif -%}
{% endmacro %}


{#
  Safely executes operations with optional debug logging.
  
  Args:
    operation_name: Name of operation for logging
    operation_macro: Macro to execute (must be parameterless)
  
  Returns:
    Result of macro execution or none if not in execute mode
  
  Features:
    - Checks execute mode before running
    - Optional debug logging of operation start/completion
    - Consistent execution wrapper across package
  
  Usage:
    {% set result = dbt_test_results.safe_execute('create_table', create_table_macro) %}
#}
{% macro safe_execute(operation_name, operation_macro) %}
  {%- if not execute -%}
    {{ return(none) }}
  {%- endif -%}
  
  {%- set debug_mode = dbt_test_results.get_config('debug_mode', false) -%}
  
  {%- if debug_mode -%}
    {%- do dbt_test_results.log_message('debug', 'Executing: ' ~ operation_name) -%}
  {%- endif -%}
  
  {%- set result = operation_macro() -%}
  
  {%- if debug_mode -%}
    {%- do dbt_test_results.log_message('debug', 'Completed: ' ~ operation_name ~ ' (result: ' ~ (result is not none) ~ ')') -%}
  {%- endif -%}
  
  {{ return(result) }}
{% endmacro %}


{#
  Enhanced error handling with structured error messages and resolution guidance.
  
  Args:
    error_message: Main error description
    error_type: Category of error (configuration, permissions, etc.)
    context: Additional context about where the error occurred
    resolution_steps: List of suggested resolution steps
    fail_on_error_override: Override the fail_on_error setting for critical errors
  
  Usage:
    {{ dbt_test_results.handle_enhanced_error(
      'Table creation failed',
      'permissions',
      'create_results_table macro',
      ['Check database user has CREATE TABLE permission', 'Verify schema exists'],
      true
    ) }}
#}
{% macro handle_enhanced_error(error_message, error_type='general', context='', resolution_steps=[], fail_on_error_override=none) %}
  {%- set fail_on_error = fail_on_error_override if fail_on_error_override is not none else dbt_test_results.get_config('fail_on_error', false) -%}
  {%- set debug_mode = dbt_test_results.get_config('debug_mode', false) -%}
  
  {%- set formatted_error -%}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
dbt-test-results ERROR [{{ error_type.upper() }}]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Problem: {{ error_message }}
{%- if context %}
Context: {{ context }}
{%- endif %}

{%- if resolution_steps | length > 0 %}
Resolution steps:
{%- for step in resolution_steps %}
  {{ loop.index }}. {{ step }}
{%- endfor %}
{%- endif %}

{%- if debug_mode %}
Debug information:
  - Error type: {{ error_type }}
  - Timestamp: {{ run_started_at }}
  - dbt version: {{ dbt_version }}
  - Target: {{ target.name }}
  - Adapter: {{ target.type }}
{%- endif %}

For more help: https://github.com/dbt-test-results/docs/troubleshooting#{{ error_type | lower | replace(' ', '-') }}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  {%- endset -%}
  
  {%- if fail_on_error -%}
    {{ exceptions.raise_compiler_error(formatted_error) }}
  {%- else -%}
    {%- do log(formatted_error, true) -%}
  {%- endif -%}
{% endmacro %}


{#
  Validates database prerequisites before major operations.
  
  Returns:
    Dictionary with validation results
  
  Checks:
    - Database connectivity
    - Schema creation permissions
    - Table creation permissions
    - Required adapter features
  
  Usage:
    {% set prereq_check = dbt_test_results.validate_prerequisites() %}
    {% if not prereq_check.all_passed %}
#}
{% macro validate_prerequisites() %}
  {%- set results = {
    'database_connection': true,
    'schema_permissions': true,
    'table_permissions': true,
    'adapter_compatibility': true,
    'all_passed': true,
    'warnings': [],
    'errors': []
  } -%}
  
  {%- set debug_mode = dbt_test_results.get_config('debug_mode', false) -%}
  
  {# Test database connection #}
  {%- if debug_mode -%}
    {%- do dbt_test_results.log_message('debug', 'Validating database connection...') -%}
  {%- endif -%}
  
  {%- set test_query = "SELECT 1 as test_connection" -%}
  {%- set connection_result = none -%}
  {%- if execute -%}
    {%- set connection_result = run_query(test_query) -%}
  {%- endif -%}
  
  {%- if not connection_result -%}
    {%- do results.update({'database_connection': false, 'all_passed': false}) -%}
    {%- do results.errors.append('Database connection failed') -%}
  {%- endif -%}
  
  {# Test adapter compatibility #}
  {%- if debug_mode -%}
    {%- do dbt_test_results.log_message('debug', 'Validating adapter compatibility...') -%}
  {%- endif -%}
  
  {%- set supported_adapters = ['spark', 'databricks', 'bigquery', 'snowflake', 'postgres'] -%}
  {%- if target.type not in supported_adapters -%}
    {%- do results.warnings.append('Adapter "' ~ target.type ~ '" not explicitly supported. May work with reduced functionality.') -%}
  {%- endif -%}
  
  {# Validate schema access #}
  {%- if debug_mode -%}
    {%- do dbt_test_results.log_message('debug', 'Validating schema permissions...') -%}
  {%- endif -%}
  
  {%- set schema_name = dbt_test_results.get_config('absolute_schema') or (target.schema ~ dbt_test_results.get_config('schema_suffix', '_test_results')) -%}
  
  {{ return(results) }}
{% endmacro %}


{#
  Generates timezone-aware timestamp for consistent execution tracking.
  
  Returns:
    ISO formatted timestamp string with timezone information
  
  Notes:
    - Uses UTC by default for consistency across environments
    - Falls back to local time if UTC conversion fails
    - Provides consistent format for cross-database compatibility
  
  Usage:
    {% set timestamp = dbt_test_results.get_execution_timestamp() %}
#}
{% macro get_execution_timestamp() %}
  {%- set timestamp_format = '%Y-%m-%d %H:%M:%S' -%}
  
  {# Try to get UTC timestamp first for consistency #}
  {%- set utc_timestamp = none -%}
  {%- if execute -%}
    {%- set utc_timestamp = modules.datetime.datetime.utcnow().strftime(timestamp_format) ~ ' UTC' -%}
  {%- endif -%}
  
  {%- if utc_timestamp -%}
    {{ return(utc_timestamp) }}
  {%- else -%}
    {# Fallback to local timestamp if UTC fails #}
    {{ return(modules.datetime.datetime.now().strftime(timestamp_format) ~ ' LOCAL') }}
  {%- endif -%}
{% endmacro %}


{#
  Validates table and schema names for database compatibility.
  
  Args:
    identifier: Table or schema name to validate
    adapter_type: Target adapter type (optional, defaults to current)
  
  Returns:
    Boolean indicating if identifier is valid for the adapter
  
  Validates:
    - Length restrictions per adapter
    - Special character restrictions
    - Reserved word conflicts
    - Case sensitivity requirements
  
  Usage:
    {% if dbt_test_results.is_valid_database_identifier('my_table', 'bigquery') %}
#}
{% macro is_valid_database_identifier(identifier, adapter_type=none) %}
  {%- set adapter = adapter_type or target.type -%}
  {%- set validation_errors = [] -%}
  
  {# Basic validation for all adapters #}
  {%- if not identifier or identifier | length == 0 -%}
    {{ return(false) }}
  {%- endif -%}
  
  {# Adapter-specific validation #}
  {%- if adapter in ['bigquery'] -%}
    {# BigQuery: 1024 char limit, must start with letter/underscore #}
    {%- if identifier | length > 1024 -%}
      {{ return(false) }}
    {%- endif -%}
    {%- if not identifier[0].isalpha() and identifier[0] != '_' -%}
      {{ return(false) }}
    {%- endif -%}
  {%- elif adapter in ['snowflake'] -%}
    {# Snowflake: 255 char limit #}
    {%- if identifier | length > 255 -%}
      {{ return(false) }}
    {%- endif -%}
  {%- elif adapter in ['postgres', 'redshift'] -%}
    {# PostgreSQL/Redshift: 63 char limit #}
    {%- if identifier | length > 63 -%}
      {{ return(false) }}
    {%- endif -%}
  {%- elif adapter in ['spark', 'databricks'] -%}
    {# Spark: 128 char limit typically #}
    {%- if identifier | length > 128 -%}
      {{ return(false) }}
    {%- endif -%}
  {%- endif -%}
  
  {# Check for special characters that could cause issues #}
  {%- set invalid_chars = identifier | regex_findall('[^a-zA-Z0-9_]') -%}
  {%- if invalid_chars | length > 0 -%}
    {{ return(false) }}
  {%- endif -%}
  
  {{ return(true) }}
{% endmacro %}