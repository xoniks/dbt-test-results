-- Validation queries to verify test results are stored correctly
-- This file contains SQL queries that can be run to validate the package functionality

-- Test 1: Verify all expected test result tables exist
SELECT 
  'test_results_tables_exist' as test_name,
  CASE 
    WHEN COUNT(*) = 4 THEN 'PASS'
    ELSE 'FAIL'
  END as test_result,
  COUNT(*) as actual_count,
  4 as expected_count,
  'Should have 4 test result tables' as description
FROM (
  SELECT table_name
  FROM information_schema.tables 
  WHERE table_schema LIKE '%test_results%'
    AND table_name IN (
      'customers_test_log', 
      'orders_test_results', 
      'shared_test_results', 
      'special_chars_test_results'
    )
)

UNION ALL

-- Test 2: Verify test results contain expected columns
SELECT 
  'test_results_schema_valid' as test_name,
  CASE 
    WHEN COUNT(*) >= 14 THEN 'PASS'
    ELSE 'FAIL'
  END as test_result,
  COUNT(*) as actual_count,
  14 as expected_count,
  'Should have at least 14 required columns in test results tables' as description
FROM information_schema.columns
WHERE table_schema LIKE '%test_results%'
  AND table_name = 'customers_test_log'
  AND column_name IN (
    'execution_id', 'execution_timestamp', 'model_name', 'test_name', 
    'test_type', 'column_name', 'status', 'execution_time_seconds',
    'failures', 'message', 'dbt_version', 'test_unique_id',
    'compiled_code_checksum', 'additional_metadata'
  )

UNION ALL

-- Test 3: Verify test results contain data
SELECT 
  'test_results_contain_data' as test_name,
  CASE 
    WHEN total_records > 0 THEN 'PASS'
    ELSE 'FAIL'
  END as test_result,
  total_records as actual_count,
  1 as expected_count,
  'Test result tables should contain at least some records' as description
FROM (
  SELECT 
    (SELECT COUNT(*) FROM {{ target.schema }}_test_results.customers_test_log) +
    (SELECT COUNT(*) FROM {{ target.schema }}_test_results.orders_test_results) +
    (SELECT COUNT(*) FROM {{ target.schema }}_test_results.shared_test_results) +
    (SELECT COUNT(*) FROM {{ target.schema }}_test_results.special_chars_test_results) as total_records
)

UNION ALL

-- Test 4: Verify failed tests are captured
SELECT 
  'failed_tests_captured' as test_name,
  CASE 
    WHEN failed_count > 0 THEN 'PASS'
    ELSE 'FAIL'
  END as test_result,
  failed_count as actual_count,
  1 as expected_count,
  'Should capture some failed tests' as description
FROM (
  SELECT COUNT(*) as failed_count
  FROM {{ target.schema }}_test_results.customers_test_log
  WHERE status = 'fail'
)

UNION ALL

-- Test 5: Verify different test types are captured
SELECT 
  'test_types_variety' as test_name,
  CASE 
    WHEN unique_test_types >= 3 THEN 'PASS'
    ELSE 'FAIL'
  END as test_result,
  unique_test_types as actual_count,
  3 as expected_count,
  'Should capture at least 3 different test types' as description
FROM (
  SELECT COUNT(DISTINCT test_type) as unique_test_types
  FROM {{ target.schema }}_test_results.customers_test_log
)

UNION ALL

-- Test 6: Verify shared test results table has data from multiple models
SELECT 
  'shared_table_multiple_models' as test_name,
  CASE 
    WHEN unique_models >= 2 THEN 'PASS'
    ELSE 'FAIL'
  END as test_result,
  unique_models as actual_count,
  2 as expected_count,
  'Shared test results table should have data from multiple models' as description
FROM (
  SELECT COUNT(DISTINCT model_name) as unique_models
  FROM {{ target.schema }}_test_results.shared_test_results
)

UNION ALL

-- Test 7: Verify execution timestamps are recent
SELECT 
  'execution_timestamps_recent' as test_name,
  CASE 
    WHEN recent_executions > 0 THEN 'PASS'
    ELSE 'FAIL'
  END as test_result,
  recent_executions as actual_count,
  1 as expected_count,
  'Should have recent execution timestamps' as description
FROM (
  SELECT COUNT(*) as recent_executions
  FROM {{ target.schema }}_test_results.customers_test_log
  WHERE execution_timestamp >= CURRENT_TIMESTAMP() - INTERVAL 1 HOUR
)

UNION ALL

-- Test 8: Verify execution IDs are consistent within execution
SELECT 
  'execution_ids_consistent' as test_name,
  CASE 
    WHEN execution_id_count = 1 THEN 'PASS'
    ELSE 'FAIL'
  END as test_result,
  execution_id_count as actual_count,
  1 as expected_count,
  'All tests in same execution should have same execution_id' as description
FROM (
  SELECT COUNT(DISTINCT execution_id) as execution_id_count
  FROM {{ target.schema }}_test_results.customers_test_log
  WHERE execution_timestamp = (
    SELECT MAX(execution_timestamp) 
    FROM {{ target.schema }}_test_results.customers_test_log
  )
)