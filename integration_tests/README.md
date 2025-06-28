# Integration Tests for dbt-test-results

This directory contains comprehensive integration tests for the dbt-test-results package. These tests validate the package functionality across different scenarios and edge cases.

## Test Structure

### Test Models

The integration tests include several test models that cover different scenarios:

1. **customers** - Basic functionality testing
   - Tests: unique, not_null, accepted_values
   - Results table: `customers_test_log`
   - Includes intentional test failures for validation

2. **orders** - Relationships and complex scenarios
   - Tests: unique, not_null, relationships, custom tests
   - Results table: `orders_test_results`
   - Tests foreign key relationships to customers table

3. **products** & **inventory** - Shared results table scenario
   - Both models store results in: `shared_test_results`
   - Tests multiple models using the same results table
   - Validates proper data segregation and identification

4. **special_chars_table** - Edge cases and special characters
   - Tests handling of special characters in data and names
   - Results table: `special_chars_test_results`
   - Validates SQL escaping and edge case handling

### Test Scenarios Covered

- ✅ **Basic functionality**: Single model with simple tests
- ✅ **Multiple models**: Different models with separate results tables  
- ✅ **Shared results table**: Multiple models using same results table
- ✅ **Different test types**: not_null, unique, accepted_values, relationships, custom tests
- ✅ **Edge cases**: Special characters, long names, null values
- ✅ **Intentional failures**: Tests that are designed to fail for validation
- ✅ **Configuration variations**: Different package configurations
- ✅ **Performance testing**: Different batch sizes and processing options

## Running the Tests

### Prerequisites

1. **Database Connection**: Set up a Databricks connection (or modify for your preferred warehouse)
2. **dbt Installation**: Ensure dbt-core and appropriate adapter are installed
3. **Profiles Configuration**: Copy and configure the profiles template

### Setup

1. Copy the profiles template and configure your connection:
```bash
cp profiles.yml.template profiles.yml
# Edit profiles.yml with your database connection details
```

2. Or add the profile to your global dbt profiles:
```bash
cp profiles.yml.template ~/.dbt/profiles.yml
# Edit ~/.dbt/profiles.yml with your connection details
```

### Running Tests

#### Option 1: Use the automated script (recommended)

```bash
cd integration_tests
./run_integration_tests.sh
```

This script will:
- Install dependencies
- Verify database connection
- Build test models
- Run tests (triggering test result storage)
- Validate results
- Test different configurations
- Provide a summary of results

#### Option 2: Manual execution

```bash
cd integration_tests

# Install dependencies
dbt deps

# Verify connection
dbt debug

# Build models
dbt run

# Run tests (this triggers test result storage)
dbt test --store-failures

# Validate results
dbt run-operation query --args '{sql: "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema LIKE \"%test_results%\""}'
```

### Validation Queries

After running tests, you can manually validate the results:

```sql
-- Check that test result tables exist
SELECT table_name, table_schema
FROM information_schema.tables 
WHERE table_schema LIKE '%test_results%'
ORDER BY table_name;

-- Check test result content
SELECT 
  table_name,
  COUNT(*) as total_records,
  SUM(CASE WHEN status = 'pass' THEN 1 ELSE 0 END) as passed_tests,
  SUM(CASE WHEN status = 'fail' THEN 1 ELSE 0 END) as failed_tests
FROM (
  SELECT 'customers_test_log' as table_name, status FROM your_schema_test_results.customers_test_log
  UNION ALL
  SELECT 'orders_test_results' as table_name, status FROM your_schema_test_results.orders_test_results
  UNION ALL
  SELECT 'shared_test_results' as table_name, status FROM your_schema_test_results.shared_test_results
)
GROUP BY table_name;

-- Check for different test types
SELECT DISTINCT test_type, COUNT(*) as count
FROM your_schema_test_results.customers_test_log
GROUP BY test_type
ORDER BY test_type;
```

## Expected Results

### Test Tables Created
- `customers_test_log` - Results from customers model tests
- `orders_test_results` - Results from orders model tests  
- `shared_test_results` - Combined results from products and inventory models
- `special_chars_test_results` - Results from special characters testing

### Test Results Expected
- **Passing tests**: Basic valid data tests should pass
- **Failing tests**: Intentionally designed failures should be recorded
- **Different test types**: unique, not_null, accepted_values, relationships, custom
- **Multiple models**: Shared results table should contain data from both products and inventory

### Validation Criteria

✅ All expected test result tables are created  
✅ Test results contain expected schema columns  
✅ Both passing and failing tests are recorded  
✅ Different test types are captured  
✅ Shared results table contains data from multiple models  
✅ Execution timestamps are recent  
✅ Execution IDs are consistent within test runs  
✅ Special characters are handled correctly  
✅ Configuration validation works as expected  

## Troubleshooting

### Common Issues

1. **Connection Errors**
   - Verify profiles.yml configuration
   - Check database permissions
   - Ensure network connectivity

2. **No Test Results Stored**
   - Check that `store_test_results` is configured in schema.yml
   - Verify package variables in dbt_project.yml
   - Check logs for error messages

3. **Missing Tables**
   - Ensure `auto_create_tables: true` in configuration
   - Check schema permissions
   - Verify target schema configuration

4. **Performance Issues**
   - Reduce `batch_size` in configuration
   - Check database cluster size
   - Monitor query execution times

### Debug Mode

Enable debug logging for detailed troubleshooting:

```yaml
vars:
  dbt_test_results:
    debug_mode: true
    logging:
      level: "debug"
```

## Configuration Testing

The integration tests cover various configuration scenarios:

- Default configuration
- Failed tests only
- Different batch sizes
- Custom schema names
- Filtering options
- Error handling modes

## Contributing

When adding new test scenarios:

1. Add new test models to `models/`
2. Configure tests in `schema.yml`
3. Update validation queries if needed
4. Add documentation to this README
5. Test with different database adapters if possible

## Support

If you encounter issues with the integration tests:

1. Check the troubleshooting section above
2. Review dbt logs for error messages
3. Validate your database connection independently
4. Open an issue with detailed error information