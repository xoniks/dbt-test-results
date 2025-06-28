# 🚀 Quick Start Guide

Get started with dbt-test-results in 5 minutes! This example shows the minimal setup required to automatically store your dbt test results.

## 📋 Prerequisites

- dbt-core installed (`pip install dbt-core`)
- Database adapter installed (e.g., `pip install dbt-databricks`)
- Database connection configured in `profiles.yml`

## 🏗️ Setup

### 1. Copy Files to Your Project

Copy these files to your existing dbt project:
- `dbt_project.yml` - Add the package configuration
- `models/customers.sql` - Sample model
- `models/schema.yml` - Tests with `store_test_results` configuration

### 2. Install the Package

Add to your `packages.yml`:
```yaml
packages:
  - git: "https://github.com/xoniks/dbt-test-results.git"
    revision: main
```

Then run:
```bash
dbt deps
```

### 3. Configure Your `dbt_project.yml`

Add these configurations to your existing `dbt_project.yml`:

```yaml
# Package dependencies
packages:
  - git: "https://github.com/xoniks/dbt-test-results.git"
    revision: main

# Package configuration
vars:
  dbt_test_results:
    enabled: true
    schema_suffix: "_test_results"
    auto_create_tables: true
    auto_create_schemas: true
    table_config:
      file_format: "delta"
      table_properties:
        "delta.autoOptimize.optimizeWrite": "true"

# Enable test result storage
on-run-end:
  - "{% if execute %}{{ dbt_test_results.store_test_results() }}{% endif %}"
```

### 4. Configure Test Result Storage

In your `models/schema.yml`, add the `store_test_results` configuration:

```yaml
models:
  - name: your_model
    config:
      store_test_results: "your_model_test_log"  # 🔥 This enables storage!
    columns:
      - name: id
        tests:
          - unique
          - not_null
```

## 🎯 Run the Example

### 1. Build Your Models
```bash
dbt run
```

### 2. Run Tests (This Triggers Storage)
```bash
dbt test
```

### 3. Check Results

After running tests, you should see:
- New schema: `your_schema_test_results`
- New table: `customers_test_log`
- Test results stored automatically!

Query your results:
```sql
SELECT *
FROM your_schema_test_results.customers_test_log
ORDER BY execution_timestamp DESC;
```

## 📊 What You'll See

The test results table will contain:
- `execution_id` - Unique ID for this test run
- `execution_timestamp` - When tests were run
- `model_name` - Which model was tested (`customers`)
- `test_name` - Name of the specific test
- `test_type` - Type of test (`unique`, `not_null`, etc.)
- `status` - Test result (`pass`, `fail`, `error`)
- `failures` - Number of failing records
- And more metadata!

## ✅ Success Indicators

You'll know it's working when:
1. ✅ `dbt test` completes without errors
2. ✅ You see log messages like "dbt-test-results: Storing X results..."
3. ✅ New test results schema/table appears in your database
4. ✅ Test results data is populated

## 🔧 Customization

### Change Results Table Name
```yaml
config:
  store_test_results: "my_custom_test_log"
```

### Use Different Schema
```yaml
vars:
  dbt_test_results:
    schema_suffix: "_audit"  # Results go to your_schema_audit
```

### Add Multiple Models
```yaml
models:
  - name: customers
    config:
      store_test_results: "customers_test_log"
  
  - name: orders  
    config:
      store_test_results: "orders_test_log"
```

## 🐛 Troubleshooting

### No Results Stored?
1. Check that `store_test_results` is in your schema.yml
2. Verify the `on-run-end` hook is in dbt_project.yml
3. Look for error messages in dbt logs
4. Enable debug mode: `debug_mode: true`

### Permission Errors?
1. Ensure your database user can create schemas/tables
2. Check that target schema exists or `auto_create_schemas: true`

### Package Not Found?
1. Run `dbt deps` after adding to packages.yml
2. Check internet connection for git access
3. Verify package syntax in packages.yml

## 📈 Next Steps

Once this is working:
1. 📖 Check [Advanced Examples](../advanced/) for sophisticated patterns
2. ⚙️ Review [Configuration Options](../configurations/) for optimization
3. 🧪 Run [Integration Tests](../../integration_tests/) for validation
4. 📚 Read the [Full Documentation](../../README.md) for all features

## 💡 Pro Tips

- Start with one model to verify functionality
- Use debug mode (`debug_mode: true`) for troubleshooting
- Monitor table sizes in production environments
- Set up automated cleanup with `retention_days`
- Use shared results tables for related models

Happy testing! 🎉