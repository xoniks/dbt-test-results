{#
  Performance monitoring and logging capabilities for dbt-test-results package.
  
  This file provides comprehensive monitoring, metrics collection, and debugging
  capabilities to help optimize performance and troubleshoot issues.
#}

{#
  Tracks execution time for operations with detailed metrics.
  
  Args:
    operation_name: Name of the operation being tracked
    operation_macro: Macro to execute and time (must be parameterless)
    
  Returns:
    Result of the operation macro along with execution metrics
    
  Usage:
    {% set result = dbt_test_results.track_execution_time('table_creation', create_table_macro) %}
#}
{% macro track_execution_time(operation_name, operation_macro) %}
  {%- set start_time = modules.datetime.datetime.now() -%}
  {%- set start_timestamp = start_time.strftime('%Y-%m-%d %H:%M:%S.%f') -%}
  
  {%- do dbt_test_results.log_message('debug', 'Starting operation: ' ~ operation_name ~ ' at ' ~ start_timestamp) -%}
  
  {%- set result = operation_macro() -%}
  
  {%- set end_time = modules.datetime.datetime.now() -%}
  {%- set end_timestamp = end_time.strftime('%Y-%m-%d %H:%M:%S.%f') -%}
  {%- set duration_seconds = (end_time - start_time).total_seconds() -%}
  {%- set duration_ms = duration_seconds * 1000 -%}
  
  {%- set execution_metrics = {
    'operation_name': operation_name,
    'start_time': start_timestamp,
    'end_time': end_timestamp,
    'duration_seconds': duration_seconds,
    'duration_ms': duration_ms,
    'success': result is not none and result != false,
    'args_count': 0
  } -%}
  
  {%- do dbt_test_results.log_performance_metrics('execution_timing', execution_metrics) -%}
  
  {%- if duration_seconds > 10 -%}
    {%- do dbt_test_results.log_message('warn', 'Slow operation detected: ' ~ operation_name ~ ' took ' ~ duration_seconds ~ 's') -%}
  {%- endif -%}
  
  {{ return(result) }}
{% endmacro %}


{#
  Monitors memory usage during test result processing.
  
  Args:
    operation_stage: Stage of processing (parsing, batching, inserting)
    data_size: Size of data being processed
    
  Returns:
    Dictionary with memory usage estimates and recommendations
    
  Usage:
    {% set memory_info = dbt_test_results.monitor_memory_usage('parsing', 5000) %}
#}
{% macro monitor_memory_usage(operation_stage, data_size) %}
  {%- set memory_per_record = 1024 -%}  {# Estimated bytes per test result #}
  {%- set estimated_memory_bytes = data_size * memory_per_record -%}
  {%- set estimated_memory_mb = estimated_memory_bytes / (1024 * 1024) -%}
  
  {%- set memory_info = {
    'operation_stage': operation_stage,
    'data_size': data_size,
    'estimated_memory_bytes': estimated_memory_bytes,
    'estimated_memory_mb': estimated_memory_mb,
    'memory_per_record': memory_per_record,
    'timestamp': modules.datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
  } -%}
  
  {%- do dbt_test_results.log_performance_metrics('memory_usage', memory_info) -%}
  
  {%- if estimated_memory_mb > 100 -%}
    {%- do dbt_test_results.log_message('warn', 'High memory usage detected: ' ~ estimated_memory_mb ~ 'MB for ' ~ data_size ~ ' records') -%}
    {%- set recommended_batch_size = (50 * 1024 * 1024) // memory_per_record -%}  {# 50MB batches #}
    {%- do dbt_test_results.log_message('info', 'Consider reducing batch_size to ' ~ recommended_batch_size ~ ' for memory optimization') -%}
  {%- endif -%}
  
  {{ return(memory_info) }}
{% endmacro %}


{#
  Collects comprehensive performance statistics during package execution.
  
  Returns:
    Dictionary with detailed performance statistics
    
  Usage:
    {% set stats = dbt_test_results.collect_performance_statistics() %}
#}
{% macro collect_performance_statistics() %}
  {%- set adapter_caps = dbt_test_results.get_adapter_capabilities() -%}
  {%- set config = dbt_test_results.get_config() -%}
  {%- set current_time = modules.datetime.datetime.now() -%}
  
  {%- set performance_stats = {
    'collection_timestamp': current_time.strftime('%Y-%m-%d %H:%M:%S'),
    'adapter_type': adapter_caps.adapter_type,
    'dbt_version': dbt_test_results.get_dbt_version(),
    'package_config': {
      'batch_size': dbt_test_results.get_config('batch_size', 1000),
      'use_merge_strategy': dbt_test_results.get_config('use_merge_strategy', false),
      'enable_parallel_processing': dbt_test_results.get_config('enable_parallel_processing', false),
      'debug_mode': dbt_test_results.get_config('debug_mode', false)
    },
    'adapter_capabilities': adapter_caps,
    'system_info': {
      'target_name': target.name,
      'target_schema': target.schema,
      'target_database': target.database,
      'threads': target.threads
    }
  } -%}
  
  {%- do dbt_test_results.log_performance_metrics('system_statistics', performance_stats) -%}
  
  {{ return(performance_stats) }}
{% endmacro %}


{#
  Creates a performance monitoring dashboard query.
  
  Args:
    schema_name: Schema containing test results tables
    time_period_days: Number of days to include in analysis
    
  Returns:
    SQL query string for performance dashboard
    
  Usage:
    {% set dashboard_sql = dbt_test_results.create_performance_dashboard('analytics_test_results', 30) %}
#}
{% macro create_performance_dashboard(schema_name, time_period_days=30) %}
  {%- set dashboard_sql -%}
    -- dbt-test-results Performance Dashboard
    -- Generated on {{ modules.datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S') }}
    
    WITH test_results_summary AS (
      SELECT 
        DATE(execution_timestamp) as execution_date,
        COUNT(*) as total_tests,
        SUM(CASE WHEN status = 'pass' THEN 1 ELSE 0 END) as passed_tests,
        SUM(CASE WHEN status = 'fail' THEN 1 ELSE 0 END) as failed_tests,
        SUM(CASE WHEN status = 'error' THEN 1 ELSE 0 END) as error_tests,
        COUNT(DISTINCT model_name) as unique_models,
        COUNT(DISTINCT test_type) as unique_test_types,
        AVG(CASE WHEN execution_time_seconds > 0 THEN execution_time_seconds ELSE NULL END) as avg_execution_time,
        MAX(execution_time_seconds) as max_execution_time,
        COUNT(DISTINCT execution_id) as execution_batches
      FROM {{ schema_name }}.test_results
      WHERE execution_timestamp >= CURRENT_DATE() - INTERVAL {{ time_period_days }} DAYS
      GROUP BY DATE(execution_timestamp)
    ),
    
    model_performance AS (
      SELECT 
        model_name,
        COUNT(*) as total_tests,
        AVG(CASE WHEN status = 'pass' THEN 1.0 ELSE 0.0 END) as pass_rate,
        AVG(CASE WHEN execution_time_seconds > 0 THEN execution_time_seconds ELSE NULL END) as avg_execution_time,
        COUNT(DISTINCT test_type) as test_type_coverage
      FROM {{ schema_name }}.test_results
      WHERE execution_timestamp >= CURRENT_DATE() - INTERVAL {{ time_period_days }} DAYS
      GROUP BY model_name
    ),
    
    test_type_performance AS (
      SELECT 
        test_type,
        COUNT(*) as total_executions,
        AVG(CASE WHEN status = 'pass' THEN 1.0 ELSE 0.0 END) as pass_rate,
        AVG(CASE WHEN execution_time_seconds > 0 THEN execution_time_seconds ELSE NULL END) as avg_execution_time,
        COUNT(DISTINCT model_name) as models_covered
      FROM {{ schema_name }}.test_results
      WHERE execution_timestamp >= CURRENT_DATE() - INTERVAL {{ time_period_days }} DAYS
      GROUP BY test_type
    )
    
    SELECT 
      'Daily Summary' as metric_category,
      execution_date,
      total_tests,
      passed_tests,
      failed_tests,
      error_tests,
      ROUND(passed_tests * 100.0 / NULLIF(total_tests, 0), 2) as pass_rate_percent,
      unique_models,
      unique_test_types,
      ROUND(avg_execution_time, 3) as avg_execution_time_seconds,
      ROUND(max_execution_time, 3) as max_execution_time_seconds,
      execution_batches
    FROM test_results_summary
    
    UNION ALL
    
    SELECT 
      'Model Performance' as metric_category,
      model_name as execution_date,
      total_tests,
      NULL as passed_tests,
      NULL as failed_tests,
      NULL as error_tests,
      ROUND(pass_rate * 100, 2) as pass_rate_percent,
      test_type_coverage as unique_models,
      NULL as unique_test_types,
      ROUND(avg_execution_time, 3) as avg_execution_time_seconds,
      NULL as max_execution_time_seconds,
      NULL as execution_batches
    FROM model_performance
    
    UNION ALL
    
    SELECT 
      'Test Type Performance' as metric_category,
      test_type as execution_date,
      total_executions as total_tests,
      NULL as passed_tests,
      NULL as failed_tests,
      NULL as error_tests,
      ROUND(pass_rate * 100, 2) as pass_rate_percent,
      models_covered as unique_models,
      NULL as unique_test_types,
      ROUND(avg_execution_time, 3) as avg_execution_time_seconds,
      NULL as max_execution_time_seconds,
      NULL as execution_batches
    FROM test_type_performance
    
    ORDER BY metric_category, execution_date DESC
  {%- endset -%}
  
  {{ return(dashboard_sql) }}
{% endmacro %}


{#
  Generates performance alerts based on configurable thresholds.
  
  Args:
    schema_name: Schema containing test results
    alert_config: Dictionary with alert thresholds
    
  Returns:
    List of alert messages
    
  Usage:
    {% set alerts = dbt_test_results.generate_performance_alerts('test_results', alert_config) %}
#}
{% macro generate_performance_alerts(schema_name, alert_config=none) %}
  {%- if not alert_config -%}
    {%- set alert_config = {
      'max_execution_time_seconds': 60,
      'min_pass_rate_percent': 95,
      'max_failed_tests_per_model': 5,
      'max_avg_execution_time_seconds': 10
    } -%}
  {%- endif -%}
  
  {%- set alerts = [] -%}
  {%- set current_time = modules.datetime.datetime.now() -%}
  
  {# Check for slow executions #}
  {%- set slow_tests_sql -%}
    SELECT model_name, test_name, execution_time_seconds
    FROM {{ schema_name }}.test_results
    WHERE execution_timestamp >= CURRENT_DATE()
      AND execution_time_seconds > {{ alert_config.max_execution_time_seconds }}
    ORDER BY execution_time_seconds DESC
    LIMIT 10
  {%- endset -%}
  
  {%- set slow_tests_result = run_query(slow_tests_sql) -%}
  {%- if slow_tests_result and slow_tests_result.rows | length > 0 -%}
    {%- for row in slow_tests_result.rows -%}
      {%- do alerts.append({
        'type': 'SLOW_EXECUTION',
        'severity': 'WARNING',
        'message': 'Slow test execution: ' ~ row[1] ~ ' on ' ~ row[0] ~ ' took ' ~ row[2] ~ 's',
        'model_name': row[0],
        'test_name': row[1],
        'execution_time': row[2],
        'threshold': alert_config.max_execution_time_seconds
      }) -%}
    {%- endfor -%}
  {%- endif -%}
  
  {# Check for low pass rates #}
  {%- set low_pass_rate_sql -%}
    SELECT 
      model_name,
      COUNT(*) as total_tests,
      SUM(CASE WHEN status = 'pass' THEN 1 ELSE 0 END) as passed_tests,
      ROUND(SUM(CASE WHEN status = 'pass' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as pass_rate
    FROM {{ schema_name }}.test_results
    WHERE execution_timestamp >= CURRENT_DATE()
    GROUP BY model_name
    HAVING pass_rate < {{ alert_config.min_pass_rate_percent }}
    ORDER BY pass_rate ASC
  {%- endset -%}
  
  {%- set low_pass_rate_result = run_query(low_pass_rate_sql) -%}
  {%- if low_pass_rate_result and low_pass_rate_result.rows | length > 0 -%}
    {%- for row in low_pass_rate_result.rows -%}
      {%- do alerts.append({
        'type': 'LOW_PASS_RATE',
        'severity': 'CRITICAL',
        'message': 'Low pass rate: ' ~ row[0] ~ ' has ' ~ row[3] ~ '% pass rate (' ~ row[1] ~ ' passed out of ' ~ row[1] ~ ')',
        'model_name': row[0],
        'total_tests': row[1],
        'passed_tests': row[2],
        'pass_rate': row[3],
        'threshold': alert_config.min_pass_rate_percent
      }) -%}
    {%- endfor -%}
  {%- endif -%}
  
  {%- do dbt_test_results.log_performance_metrics('performance_alerts', {
    'alert_count': alerts | length,
    'alert_types': alerts | map(attribute='type') | list | unique,
    'timestamp': current_time.strftime('%Y-%m-%d %H:%M:%S')
  }) -%}
  
  {{ return(alerts) }}
{% endmacro %}


{#
  Logs debug information for troubleshooting package issues.
  
  Args:
    context: Context or operation being debugged
    debug_data: Data to include in debug output
    
  Usage:
    {% do dbt_test_results.log_debug_info('test_parsing', {'test_count': 100, 'models': ['a', 'b']}) %}
#}
{% macro log_debug_info(context, debug_data) %}
  {%- set debug_mode = dbt_test_results.get_config('debug_mode', false) -%}
  
  {%- if debug_mode -%}
    {%- set debug_entry = {
      'timestamp': modules.datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S.%f'),
      'context': context,
      'debug_data': debug_data,
      'target': target.name,
      'dbt_version': dbt_test_results.get_dbt_version()
    } -%}
    
    {%- do dbt_test_results.log_message('debug', 'DEBUG [' ~ context ~ ']: ' ~ debug_data | tojson) -%}
    
    {%- set detailed_debug = dbt_test_results.get_config('detailed_debug', false) -%}
    {%- if detailed_debug -%}
      {%- for key, value in debug_data.items() -%}
        {%- do dbt_test_results.log_message('debug', '  ' ~ key ~ ': ' ~ value) -%}
      {%- endfor -%}
    {%- endif -%}
  {%- endif -%}
{% endmacro %}


{#
  Creates a comprehensive health check report for the package.
  
  Returns:
    Dictionary with health check results and recommendations
    
  Usage:
    {% set health_report = dbt_test_results.create_health_check_report() %}
#}
{% macro create_health_check_report() %}
  {%- set config = var('dbt_test_results', {}) -%}
  {%- set adapter_caps = dbt_test_results.get_adapter_capabilities() -%}
  {%- set health_report = {
    'timestamp': modules.datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
    'package_enabled': config.get('enabled', true),
    'configuration_status': 'healthy',
    'adapter_compatibility': 'good',
    'performance_status': 'good',
    'recommendations': []
  } -%}
  
  {# Check configuration health #}
  {%- set batch_size = config.get('batch_size', 1000) -%}
  {%- if batch_size > adapter_caps.get('max_batch_size', 5000) -%}
    {%- set _ = health_report.update({'configuration_status': 'warning'}) -%}
    {%- do health_report.recommendations.append('Reduce batch_size to ' ~ adapter_caps.get('recommended_batch_size', 1000) ~ ' for better performance') -%}
  {%- endif -%}
  
  {# Check adapter optimization #}
  {%- if not config.get('use_merge_strategy') and adapter_caps.get('supports_merge', false) -%}
    {%- do health_report.recommendations.append('Enable use_merge_strategy for better concurrency with ' ~ adapter_caps.adapter_type) -%}
  {%- endif -%}
  
  {%- if not config.get('enable_parallel_processing') and adapter_caps.get('supports_parallel_processing', false) -%}
    {%- do health_report.recommendations.append('Consider enabling parallel processing for better performance') -%}
  {%- endif -%}
  
  {# Overall health assessment #}
  {%- if health_report.recommendations | length == 0 -%}
    {%- set _ = health_report.update({'overall_health': 'excellent'}) -%}
  {%- elif health_report.recommendations | length <= 2 -%}
    {%- set _ = health_report.update({'overall_health': 'good'}) -%}
  {%- else -%}
    {%- set _ = health_report.update({'overall_health': 'needs_attention'}) -%}
  {%- endif -%}
  
  {%- do dbt_test_results.log_performance_metrics('health_check', health_report) -%}
  
  {{ return(health_report) }}
{% endmacro %}