# dbt-test-results

<div align="center">

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![dbt-core](https://img.shields.io/badge/dbt_core->=1.0.0-orange.svg)](https://github.com/dbt-labs/dbt-core)

**Simple dbt test result logging for basic monitoring**

</div>

## 🎯 Overview

dbt-test-results is a minimal package that logs dbt test execution results. It captures basic test information and outputs it to the dbt log for monitoring purposes.

### ✨ Features

- 📝 **Simple Logging**: Logs test results to dbt output
- 🔄 **Automatic Capture**: Runs after dbt test execution
- ⚙️ **Minimal Configuration**: Basic enable/disable options

## 🚀 Quick Start

### 1. Install the Package

Create `packages.yml` in your project root:
```yaml
packages:
  - git: "https://github.com/xoniks/dbt-test-results.git"
    revision: "v0.0.1"  # Use specific version for stability
```

Run:
```bash
dbt deps
```

### 2. Configure Your Project

Add to your `dbt_project.yml`:
```yaml
# Example from my_databricks_project
name: 'my_databricks_project'
version: '1.0.0'
config-version: 2

profile: default

vars:
  dbt_test_results:
    absolute_schema: "test_results"  # Schema where test results will be stored

models:
  my_databricks_project:
    silver:
      +materialized: table
      +file_format: delta
      +schema: silver
```

### 3. Configure Models for Test Storage

In your `models/schema.yml`, add `store_test_results` config:
```yaml
version: 2

models:
  - name: silver_items
    description: Cleaned and enriched order items data
    config:
      store_test_results: "silvers_items_test_results"
    columns:
      - name: item_id
        description: Unique identifier for the order item (UUID)
        tests:
          - not_null
          - unique
      - name: product_name
        description: Name of the product
        tests:
          - not_null
          - unique
      - name: sku
        description: Product stock-keeping unit (SKU)
        tests:
          - not_null
          - unique
          - relationships:
              to: ref('bronze_products')
              field: sku
```

### 4. Run Tests

```bash
dbt test
```

That's it! Test results will be stored in `test_results.silvers_items_test_results` table.

## 📊 What You Get

After running tests, your results are stored in database tables:

```sql
SELECT * FROM test_results.silvers_items_test_results;
```

| execution_id | execution_timestamp | model_name | test_name | status | failures | test_unique_id |
|--------------|-------------------|------------|-----------|--------|----------|----------------|
| 20250715_215307 | 2025-07-15 21:53:07 | silver_items | not_null_silver_items_item_id | pass | 0 | test.my_databricks_project.not_null_silver_items_item_id.55294f32bf |
| 20250715_215307 | 2025-07-15 21:53:07 | silver_items | unique_silver_items_item_id | pass | 0 | test.my_databricks_project.unique_silver_items_item_id.5bcb6e856e |
| 20250715_215307 | 2025-07-15 21:53:07 | silver_items | unique_silver_items_product_name | fail | 10 | test.my_databricks_project.unique_silver_items_product_name.25ac031ae6 |
| 20250715_215307 | 2025-07-15 21:53:07 | silver_items | unique_silver_items_sku | fail | 10 | test.my_databricks_project.unique_silver_items_sku.6bc105dc22 |
| 20250715_215307 | 2025-07-15 21:53:07 | silver_items | unique_silver_items_product_price | fail | 7 | test.my_databricks_project.unique_silver_items_product_price.cd36bf4220 |
| 20250715_215307 | 2025-07-15 21:53:07 | silver_items | relationships_silver_items_sku__sku__ref_bronze_products_ | pass | 0 | test.my_databricks_project.relationships_silver_items_sku__sku__ref_bronze_products_.a74e12bda2 |

**Perfect for**: Test result tracking, data quality monitoring, and historical analysis

## ⚙️ Configuration

### Basic Configuration

```yaml
# dbt_project.yml
vars:
  dbt_test_results:
    absolute_schema: "test_results"  # Optional: specify schema for results
```

That's it! The package has minimal configuration options.

## 🎯 Use Cases

- **📊 Basic Monitoring**: See test results in dbt logs
- **🐛 Debugging**: Quickly identify failing tests
- **📋 Simple Reporting**: Basic test execution information

## 🛠️ Requirements

- **dbt-core**: >= 1.0.0
- **Database**: Databricks/Spark with Delta Lake (optimized for this platform)

## 🚧 Roadmap

### Planned Features

- **Source Test Support**: Capture test results for source tables (coming soon)
- **Bulk Results Table**: Optional single table for all test results across models
- **Enhanced Metadata**: Additional test execution details and performance metrics

## 🐛 Troubleshooting

### Common Issues

#### ❌ No output appearing
- Verify the on-run-end hook is properly configured
- Check that you're running `dbt test` (not just `dbt run`)

#### ❌ Hook not running
- Ensure the hook is added to your `dbt_project.yml` 
- Check that you're running `dbt test` (not just `dbt run`)
- Verify dbt version compatibility (>=1.0.0)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<div align="center">

**Simple test result logging for dbt**

[🐛 Report issues](https://github.com/xoniks/dbt-test-results/issues)

</div>
