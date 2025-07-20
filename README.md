# dbt-test-results

<div align="center">

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![dbt-core](https://img.shields.io/badge/dbt_core->=1.0.0-orange.svg)](https://github.com/dbt-labs/dbt-core)

**Simple dbt test result logging for basic monitoring**

</div>

## 🎯 Overview

dbt-test-results is a minimal package that automatically captures and stores dbt test execution results in Delta tables. It provides persistent storage for test results with minimal configuration, enabling data quality monitoring and historical analysis.

### ✨ Features

- 📝 **Automatic Storage**: Stores test results in configurable Delta tables
- 🔄 **Model Test Capture**: Captures all test types (not_null, unique, relationships, custom)
- ⚙️ **Minimal Configuration**: Single variable setup with model-level control
- 📊 **Real Results**: Captures both pass/fail status with actual failure counts
- 🏗️ **Delta Integration**: Optimized table creation with proper schema
- 🏷️ **Databricks Column Tags**: Automatically applies test metadata as column tags (optional)

## 🚀 Quick Start

### 1. Install the Package

Create `packages.yml` in your project root:
```yaml
packages:
  - git: "https://github.com/xoniks/dbt-test-results.git"
    revision: "0.0.1"  # Use specific version for stability
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
      store_test_results_tags: true  # Optional: Apply test info as Databricks column tags
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

### 4. Optional: Databricks Column Tags

When `store_test_results_tags: true` is enabled, the package automatically applies test information as Databricks column tags:

- `customer_id` column → `dbt_tests: "not_null,unique"`
- `customer_name` column → `dbt_tests: "not_null"`

These tags appear in the Databricks Catalog UI, making test coverage visible to all data consumers.

### 5. Run Tests

```bash
dbt test
```

That's it! Test results will be automatically captured and stored in `test_results.silvers_items_test_results` table.

### Example Output

```
23:15:59  dbt-test-results: Storing results for 2 configured models
23:16:33  1 of 1 OK hook: dbt_test_results.on-run-end.0 [OK in 33.84s]
23:16:34  Done. PASS=36 WARN=1 ERROR=3 SKIP=0 TOTAL=40
```

## 📊 What You Get

After running tests, your results are stored in database tables:

```sql
SELECT * FROM test_results.silvers_items_test_results;
```

| execution_id | execution_timestamp | model_name | test_name | status | failures | test_unique_id |
|--------------|-------------------|------------|-----------|--------|----------|----------------|
| 20250715_231523 | 2025-07-15 23:15:23 | silver_items | not_null_silver_items_item_id | pass | 0 | test.my_databricks_project.not_null_silver_items_item_id.55294f32bf |
| 20250715_231523 | 2025-07-15 23:15:23 | silver_items | unique_silver_items_item_id | pass | 0 | test.my_databricks_project.unique_silver_items_item_id.5bcb6e856e |
| 20250715_231523 | 2025-07-15 23:15:23 | silver_items | unique_silver_items_product_name | fail | 10 | test.my_databricks_project.unique_silver_items_product_name.25ac031ae6 |
| 20250715_231523 | 2025-07-15 23:15:23 | silver_items | unique_silver_items_sku | fail | 10 | test.my_databricks_project.unique_silver_items_sku.6bc105dc22 |
| 20250715_231523 | 2025-07-15 23:15:23 | silver_items | unique_silver_items_product_price | fail | 7 | test.my_databricks_project.unique_silver_items_product_price.cd36bf4220 |
| 20250715_231523 | 2025-07-15 23:15:23 | silver_items | relationships_silver_items_sku__sku__ref_bronze_products_ | pass | 0 | test.my_databricks_project.relationships_silver_items_sku__sku__ref_bronze_products_.a74e12bda2 |

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

- **📊 Data Quality Monitoring**: Track test pass/fail rates over time
- **🐛 Debugging**: Quickly identify failing tests with failure counts
- **📋 Historical Analysis**: Analyze test performance trends and patterns
- **🚨 Alerting**: Build monitoring dashboards and alerts on test failures
- **📈 Reporting**: Generate data quality reports for stakeholders

## 🛠️ Requirements

- **dbt-core**: >= 1.0.0
- **Database**: Databricks/Spark with Delta Lake (heavily tested and optimized)

### 📋 Platform Support

**Production Ready:**
- ✅ **Databricks/Spark with Delta Lake** - Extensively tested in production environments

**Future Roadmap:**
- 🔄 **Snowflake** - Planned for future releases
- 🔄 **BigQuery** - Planned for future releases  
- 🔄 **PostgreSQL** - Planned for future releases
- 🔄 **Redshift** - Planned for future releases

*Note: This package is currently heavily tested and optimized for Databricks. Support for additional platforms will be added based on community feedback and testing.*

## 🚧 Roadmap

### Planned Features

- **Source Test Support**: Capture test results for source tables (currently only model tests are captured)
- **Bulk Results Table**: Optional single table for all test results across models
- **Enhanced Metadata**: Additional test execution details and performance metrics
- **Multi-Platform Support**: Extend beyond Databricks to Snowflake, BigQuery, PostgreSQL, Redshift
- **Advanced Tagging**: Additional Databricks governance features and tag customization

### Current Limitations

- **Model Tests Only**: Currently captures tests for models with `store_test_results` config
- **Source Tests**: Source tests run but are not captured (planned for next release)
- **Databricks Focus**: Heavily tested on Databricks/Spark with Delta Lake; other platforms planned
- **Column Tags**: Databricks-specific feature, will not work on other platforms

## 🐛 Troubleshooting

### Common Issues

#### ❌ No tables created
- Verify models have `store_test_results` config in schema.yml
- Check that `absolute_schema` variable is set in dbt_project.yml
- Ensure you're running `dbt test` (not just `dbt run`)

#### ❌ No test results stored
- Verify the on-run-end hook is properly configured
- Check that tests are actually running and completing
- Ensure database permissions allow table creation in target schema

#### ❌ Source tests not captured
- Currently only model tests are captured (source tests are planned)
- Source tests will run but won't be stored in result tables

#### ❌ Column tags not applied (Databricks only)
- Ensure `store_test_results_tags: true` is set in model config
- Verify you have ALTER TABLE permissions in Databricks
- Column tagging feature is Databricks-specific

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<div align="center">

**Simple test result logging for dbt**

[🐛 Report issues](https://github.com/xoniks/dbt-test-results/issues)

</div>
