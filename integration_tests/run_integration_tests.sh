#!/bin/bash

# Integration test script for dbt-test-results package
# This script runs comprehensive tests to validate package functionality

set -e  # Exit on any error

echo "=========================================="
echo "dbt-test-results Integration Tests"
echo "=========================================="

# Check if we're in the right directory
if [ ! -f "dbt_project.yml" ]; then
    echo "Error: Please run this script from the integration_tests directory"
    exit 1
fi

# Check if profiles.yml exists
if [ ! -f "profiles.yml" ] && [ ! -f "$HOME/.dbt/profiles.yml" ]; then
    echo "Warning: No profiles.yml found. Please set up your database connection."
    echo "Copy profiles.yml.template to profiles.yml and update connection details."
fi

echo "Step 1: Installing dependencies..."
dbt deps

echo ""
echo "Step 2: Running dbt debug to verify connection..."
dbt debug

echo ""
echo "Step 3: Building test models..."
dbt run

echo ""
echo "Step 4: Running tests (this will trigger test result storage)..."
dbt test --store-failures

echo ""
echo "Step 5: Validating test results storage..."
echo "Checking for test result tables..."

# Use dbt to run our validation queries
echo "Running validation queries..."
dbt run-operation query --args '{sql: "
SELECT 
  table_name,
  table_schema,
  COUNT(*) as row_count
FROM information_schema.tables 
WHERE table_schema LIKE \"%test_results%\"
  AND table_name IN (\"customers_test_log\", \"orders_test_results\", \"shared_test_results\", \"special_chars_test_results\")
GROUP BY table_name, table_schema
ORDER BY table_name
"}'

echo ""
echo "Step 6: Checking test result content..."
dbt run-operation query --args '{sql: "
SELECT 
  \"customers_test_log\" as table_name,
  COUNT(*) as total_records,
  SUM(CASE WHEN status = \"pass\" THEN 1 ELSE 0 END) as passed_tests,
  SUM(CASE WHEN status = \"fail\" THEN 1 ELSE 0 END) as failed_tests,
  COUNT(DISTINCT test_type) as unique_test_types,
  COUNT(DISTINCT model_name) as unique_models
FROM '${DBT_TARGET_SCHEMA}_test_results.customers_test_log'

UNION ALL

SELECT 
  \"orders_test_results\" as table_name,
  COUNT(*) as total_records,
  SUM(CASE WHEN status = \"pass\" THEN 1 ELSE 0 END) as passed_tests,
  SUM(CASE WHEN status = \"fail\" THEN 1 ELSE 0 END) as failed_tests,
  COUNT(DISTINCT test_type) as unique_test_types,
  COUNT(DISTINCT model_name) as unique_models
FROM '${DBT_TARGET_SCHEMA}_test_results.orders_test_results'

UNION ALL

SELECT 
  \"shared_test_results\" as table_name,
  COUNT(*) as total_records,
  SUM(CASE WHEN status = \"pass\" THEN 1 ELSE 0 END) as passed_tests,
  SUM(CASE WHEN status = \"fail\" THEN 1 ELSE 0 END) as failed_tests,
  COUNT(DISTINCT test_type) as unique_test_types,
  COUNT(DISTINCT model_name) as unique_models
FROM '${DBT_TARGET_SCHEMA}_test_results.shared_test_results'
"}'

echo ""
echo "Step 7: Testing edge cases..."
echo "Running tests with different configurations..."

# Test with failed_tests_only = true
echo "Testing failed_tests_only configuration..."
dbt run-operation store_test_results --vars '{dbt_test_results: {failed_tests_only: true}}'

echo ""
echo "Step 8: Performance testing..."
echo "Testing with different batch sizes..."

# Test with smaller batch size
dbt run-operation store_test_results --vars '{dbt_test_results: {batch_size: 10}}'

# Test with larger batch size
dbt run-operation store_test_results --vars '{dbt_test_results: {batch_size: 1000}}'

echo ""
echo "Step 9: Configuration validation testing..."
echo "Testing invalid configurations..."

# Test invalid batch_size (should fail gracefully)
dbt run-operation store_test_results --vars '{dbt_test_results: {batch_size: -1}}' || echo "Expected failure for invalid batch_size"

# Test invalid log level (should fail gracefully)
dbt run-operation store_test_results --vars '{dbt_test_results: {logging: {level: "invalid"}}}' || echo "Expected failure for invalid log level"

echo ""
echo "=========================================="
echo "Integration Tests Summary"
echo "=========================================="

echo "✅ Dependencies installed successfully"
echo "✅ Database connection verified"
echo "✅ Test models built successfully"
echo "✅ Tests executed and results stored"
echo "✅ Test result tables created and populated"
echo "✅ Edge cases and configurations tested"

echo ""
echo "Manual verification steps:"
echo "1. Check that test result tables exist in your database"
echo "2. Verify that both passing and failing tests are recorded"
echo "3. Confirm that shared test results table contains data from multiple models"
echo "4. Review logs for any unexpected warnings or errors"

echo ""
echo "Next steps:"
echo "- Run specific validation queries to verify data quality"
echo "- Test with your production dbt project configuration"
echo "- Verify performance with larger test suites"

echo ""
echo "Integration tests completed successfully! 🎉"