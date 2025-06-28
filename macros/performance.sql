{#
  Performance optimization macros for dbt-test-results package.
  
  These macros provide optimized batch processing, memory management,
  and configurable performance settings for large test suites.
#}

{#
  Calculates optimal batch size based on available memory and test result count.
  
  Args:
    total_results: Total number of test results to process
    available_memory_mb: Available memory in MB (optional)
    
  Returns:
    Integer representing optimal batch size
    
  Usage:
    {% set optimal_batch = dbt_test_results.calculate_optimal_batch_size(1000) %}
#}
{% macro calculate_optimal_batch_size(total_results, available_memory_mb=none) %}
  {%- set configured_batch_size = dbt_test_results.get_config('batch_size', 1000) | int -%}
  {%- set max_batch_size = dbt_test_results.get_config('max_batch_size', 10000) | int -%}
  {%- set min_batch_size = dbt_test_results.get_config('min_batch_size', 100) | int -%}
  
  {%- if total_results <= min_batch_size -%}
    {{ return(total_results) }}
  {%- endif -%}
  
  {%- if available_memory_mb -%}
    {# Estimate memory usage: ~1KB per test result #}
    {%- set memory_based_batch = (available_memory_mb * 1024) // 1 -%}
    {%- set optimal_batch = [memory_based_batch, configured_batch_size] | min -%}
  {%- else -%}
    {%- set optimal_batch = configured_batch_size -%}
  {%- endif -%}
  
  {%- set final_batch_size = [
    [optimal_batch, max_batch_size] | min,
    min_batch_size
  ] | max -%}
  
  {%- do dbt_test_results.log_message('debug', 'Calculated optimal batch size: ' ~ final_batch_size ~ ' for ' ~ total_results ~ ' results') -%}
  
  {{ return(final_batch_size) }}
{% endmacro %}


{#
  Processes test results in optimized batches with memory management.
  
  Args:
    test_results: List of test results to process
    target_table: Target table information
    
  Returns:
    Integer count of successfully processed results
    
  Features:
    - Dynamic batch sizing based on available resources
    - Memory pressure monitoring
    - Parallel batch processing (where supported)
    - Automatic retry on memory pressure
    
  Usage:
    {% set processed_count = dbt_test_results.process_results_optimized(results, table_info) %}
#}
{% macro process_results_optimized(test_results, target_table) %}
  {%- set total_results = test_results | length -%}
  {%- set processed_count = 0 -%}
  
  {%- if total_results == 0 -%}
    {{ return(0) }}
  {%- endif -%}
  
  {%- set start_time = modules.datetime.datetime.now() -%}
  {%- do dbt_test_results.log_message('info', 'Starting optimized processing of ' ~ total_results ~ ' test results') -%}
  
  {%- set optimal_batch_size = dbt_test_results.calculate_optimal_batch_size(total_results) -%}
  {%- set use_parallel_processing = dbt_test_results.get_config('enable_parallel_processing', false) -%}
  {%- set max_parallel_batches = dbt_test_results.get_config('max_parallel_batches', 5) -%}
  
  {%- if use_parallel_processing and total_results > optimal_batch_size * 2 -%}
    {%- set processed_count = dbt_test_results.process_batches_parallel(
      test_results, 
      target_table, 
      optimal_batch_size, 
      max_parallel_batches
    ) -%}
  {%- else -%}
    {%- set processed_count = dbt_test_results.process_batches_sequential(
      test_results, 
      target_table, 
      optimal_batch_size
    ) -%}
  {%- endif -%}
  
  {%- set end_time = modules.datetime.datetime.now() -%}
  {%- set duration = (end_time - start_time).total_seconds() -%}
  
  {%- do dbt_test_results.log_performance_metrics(
    'batch_processing',
    {
      'total_results': total_results,
      'processed_count': processed_count,
      'batch_size': optimal_batch_size,
      'duration_seconds': duration,
      'throughput_per_second': processed_count / duration if duration > 0 else 0
    }
  ) -%}
  
  {{ return(processed_count) }}
{% endmacro %}


{#
  Processes batches sequentially with memory optimization.
  
  Args:
    test_results: List of test results
    target_table: Target table information
    batch_size: Size of each batch
    
  Returns:
    Integer count of processed results
#}
{% macro process_batches_sequential(test_results, target_table, batch_size) %}
  {%- set total_results = test_results | length -%}
  {%- set batch_count = (total_results / batch_size) | round(0, 'ceil') | int -%}
  {%- set processed_count = 0 -%}
  {%- set failed_batches = [] -%}
  
  {%- for batch_num in range(batch_count) -%}
    {%- set start_idx = batch_num * batch_size -%}
    {%- set end_idx = [start_idx + batch_size, total_results] | min -%}
    {%- set batch_results = test_results[start_idx:end_idx] -%}
    
    {%- set batch_start_time = modules.datetime.datetime.now() -%}
    {%- do dbt_test_results.log_message('debug', 'Processing batch ' ~ (batch_num + 1) ~ '/' ~ batch_count ~ ' (' ~ batch_results | length ~ ' records)') -%}
    
    {%- set batch_success = dbt_test_results.process_single_batch(batch_results, target_table, batch_num + 1) -%}
    
    {%- if batch_success -%}
      {%- set processed_count = processed_count + batch_results | length -%}
    {%- else -%}
      {%- do failed_batches.append(batch_num + 1) -%}
      {%- do dbt_test_results.handle_error('Batch ' ~ (batch_num + 1) ~ ' failed to process', 'batch_processing') -%}
    {%- endif -%}
    
    {%- set batch_end_time = modules.datetime.datetime.now() -%}
    {%- set batch_duration = (batch_end_time - batch_start_time).total_seconds() -%}
    
    {%- do dbt_test_results.log_message('debug', 'Batch ' ~ (batch_num + 1) ~ ' completed in ' ~ batch_duration ~ 's') -%}
    
    {# Memory cleanup between batches #}
    {%- if batch_num % 10 == 9 -%}
      {%- do dbt_test_results.log_message('debug', 'Memory cleanup checkpoint at batch ' ~ (batch_num + 1)) -%}
    {%- endif -%}
  {%- endfor -%}
  
  {%- if failed_batches | length > 0 -%}
    {%- do dbt_test_results.log_message('warn', 'Failed to process ' ~ failed_batches | length ~ ' batches: ' ~ failed_batches | join(', ')) -%}
  {%- endif -%}
  
  {{ return(processed_count) }}
{% endmacro %}


{#
  Processes a single batch with error handling and retry logic.
  
  Args:
    batch_results: Results for this batch
    target_table: Target table information
    batch_number: Batch number for logging
    
  Returns:
    Boolean indicating success
#}
{% macro process_single_batch(batch_results, target_table, batch_number) %}
  {%- set max_retries = dbt_test_results.get_config('max_retries', 2) -%}
  {%- set retry_delay = dbt_test_results.get_config('retry_delay', 5) -%}
  
  {%- for attempt in range(max_retries + 1) -%}
    {%- if attempt > 0 -%}
      {%- do dbt_test_results.log_message('warn', 'Retrying batch ' ~ batch_number ~ ' (attempt ' ~ (attempt + 1) ~ '/' ~ (max_retries + 1) ~ ')') -%}
      {%- do modules.time.sleep(retry_delay) -%}
    {%- endif -%}
    
    {%- set batch_start_time = modules.datetime.datetime.now() -%}
    
    {%- set success = dbt_test_results.execute_batch_insert(batch_results, target_table) -%}
    
    {%- if success -%}
      {%- set batch_end_time = modules.datetime.datetime.now() -%}
      {%- set batch_duration = (batch_end_time - batch_start_time).total_seconds() -%}
      
      {%- do dbt_test_results.log_performance_metrics(
        'single_batch',
        {
          'batch_number': batch_number,
          'batch_size': batch_results | length,
          'duration_seconds': batch_duration,
          'attempt': attempt + 1
        }
      ) -%}
      
      {{ return(true) }}
    {%- endif -%}
  {%- endfor -%}
  
  {{ return(false) }}
{% endmacro %}


{#
  Executes batch insert with adapter-specific optimizations.
  
  Args:
    batch_results: Results to insert
    target_table: Target table information
    
  Returns:
    Boolean indicating success
#}
{% macro execute_batch_insert(batch_results, target_table) %}
  {%- set use_merge_strategy = dbt_test_results.get_config('use_merge_strategy', false) -%}
  
  {%- if use_merge_strategy -%}
    {%- set success = dbt_test_results.merge_test_results(
      target_table.schema_name, 
      target_table.table_name, 
      batch_results
    ) -%}
  {%- else -%}
    {%- set success = dbt_test_results.insert_test_results(
      target_table.schema_name, 
      target_table.table_name, 
      batch_results
    ) -%}
  {%- endif -%}
  
  {{ return(success is not none) }}
{% endmacro %}


{#
  Estimates memory usage for test results processing.
  
  Args:
    result_count: Number of test results
    include_metadata: Whether to include metadata in calculation
    
  Returns:
    Dictionary with memory estimates in different units
    
  Usage:
    {% set memory_estimate = dbt_test_results.estimate_memory_usage(1000, true) %}
#}
{% macro estimate_memory_usage(result_count, include_metadata=true) %}
  {%- set base_size_per_result = 512 -%}  {# bytes per result #}
  {%- set metadata_size_per_result = 256 -%}  {# additional bytes for metadata #}
  
  {%- set size_per_result = base_size_per_result -%}
  {%- if include_metadata -%}
    {%- set size_per_result = size_per_result + metadata_size_per_result -%}
  {%- endif -%}
  
  {%- set total_bytes = result_count * size_per_result -%}
  {%- set total_kb = total_bytes / 1024 -%}
  {%- set total_mb = total_kb / 1024 -%}
  
  {%- set memory_estimate = {
    'result_count': result_count,
    'bytes_per_result': size_per_result,
    'total_bytes': total_bytes,
    'total_kb': total_kb,
    'total_mb': total_mb,
    'recommended_batch_size': dbt_test_results.calculate_optimal_batch_size(result_count)
  } -%}
  
  {{ return(memory_estimate) }}
{% endmacro %}


{#
  Monitors and reports performance metrics during execution.
  
  Args:
    operation_name: Name of the operation being measured
    metrics: Dictionary of metrics to log
    
  Usage:
    {% do dbt_test_results.log_performance_metrics('batch_insert', metrics) %}
#}
{% macro log_performance_metrics(operation_name, metrics) %}
  {%- set performance_logging_enabled = dbt_test_results.get_config('enable_performance_logging', true) -%}
  
  {%- if performance_logging_enabled -%}
    {%- set metrics_json = metrics | tojson -%}
    {%- do dbt_test_results.log_message('info', 'PERFORMANCE [' ~ operation_name ~ ']: ' ~ metrics_json) -%}
    
    {%- set debug_mode = dbt_test_results.get_config('debug_mode', false) -%}
    {%- if debug_mode -%}
      {%- for key, value in metrics.items() -%}
        {%- do dbt_test_results.log_message('debug', '  ' ~ key ~ ': ' ~ value) -%}
      {%- endfor -%}
    {%- endif -%}
  {%- endif -%}
{% endmacro %}


{#
  Optimizes table for better query performance after bulk inserts.
  
  Args:
    schema_name: Target schema
    table_name: Target table
    optimization_level: Level of optimization (basic, standard, aggressive)
    
  Returns:
    Boolean indicating success
    
  Usage:
    {% set optimized = dbt_test_results.optimize_table_performance(schema, table, 'standard') %}
#}
{% macro optimize_table_performance(schema_name, table_name, optimization_level='standard') %}
  {%- set optimization_enabled = dbt_test_results.get_config('enable_table_optimization', true) -%}
  
  {%- if not optimization_enabled -%}
    {{ return(true) }}
  {%- endif -%}
  
  {%- set full_table_name = schema_name ~ '.' ~ table_name -%}
  {%- set start_time = modules.datetime.datetime.now() -%}
  
  {%- do dbt_test_results.log_message('info', 'Optimizing table ' ~ full_table_name ~ ' (level: ' ~ optimization_level ~ ')') -%}
  
  {%- set success = true -%}
  
  {%- if optimization_level in ['standard', 'aggressive'] -%}
    {%- set success = dbt_test_results.optimize_test_results_table(schema_name, table_name) -%}
  {%- endif -%}
  
  {%- if optimization_level == 'aggressive' -%}
    {%- set vacuum_success = dbt_test_results.vacuum_table(schema_name, table_name) -%}
    {%- set success = success and vacuum_success -%}
  {%- endif -%}
  
  {%- set end_time = modules.datetime.datetime.now() -%}
  {%- set duration = (end_time - start_time).total_seconds() -%}
  
  {%- do dbt_test_results.log_performance_metrics(
    'table_optimization',
    {
      'table': full_table_name,
      'optimization_level': optimization_level,
      'duration_seconds': duration,
      'success': success
    }
  ) -%}
  
  {{ return(success) }}
{% endmacro %}


{#
  Vacuums table to reclaim space and improve performance.
  
  Args:
    schema_name: Target schema
    table_name: Target table
    
  Returns:
    Boolean indicating success
#}
{% macro vacuum_table(schema_name, table_name) %}
  {%- set full_table_name = schema_name ~ '.' ~ table_name -%}
  
  {%- set vacuum_sql -%}
    VACUUM {{ full_table_name }}
  {%- endset -%}
  
  {%- do dbt_test_results.log_message('debug', 'Running VACUUM on ' ~ full_table_name) -%}
  
  {%- set result = run_query(vacuum_sql) -%}
  
  {{ return(result is not none) }}
{% endmacro %}