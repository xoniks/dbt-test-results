# Getting Started with dbt-test-results

## 🎯 What You'll Learn

By the end of this guide, you'll have:
- dbt-test-results installed and configured
- Test results automatically captured and stored
- Basic queries to analyze your data quality trends
- Understanding of how to expand usage across your project

**⏱️ Estimated time:** 15-30 minutes depending on your dbt experience

---

## 🏁 Quick Start (5 minutes)

### Step 1: Install the Package

Add dbt-test-results to your `packages.yml` file:

```yaml
# packages.yml
packages:
  - git: https://github.com/your-org/dbt-test-results.git
    revision: v1.0.0
  - package: dbt-labs/dbt_utils
    version: [">=0.8.0", "<2.0.0"]
```

**Install dependencies:**
```bash
dbt deps
```

### Step 2: Basic Configuration

Add this to your `dbt_project.yml`:

```yaml
# dbt_project.yml
vars:
  dbt_test_results:
    enabled: true
```

### Step 3: Configure Your First Model

Add test result tracking to a model in your `schema.yml`:

```yaml
# models/schema.yml
models:
  - name: customers  # Replace with your model name
    config:
      store_test_results: "customer_test_history"
    columns:
      - name: customer_id
        tests:
          - unique
          - not_null
      - name: email
        tests:
          - unique
          - not_null
```

### Step 4: Run Tests and See Results

```bash
# Run your tests
dbt test --models customers

# Query your test results
# (Replace 'your_schema' with your actual schema name)
select * from your_schema.customer_test_history
order by execution_timestamp desc
limit 10;
```

🎉 **You're done!** You should see test results with execution times, status, and metadata.

---

## 🔧 Detailed Setup Guide

### Prerequisites

**Required:**
- dbt-core >= 1.0.0
- Supported database (Databricks, BigQuery, Snowflake, or PostgreSQL)
- Basic familiarity with dbt models and tests

**Helpful to have:**
- Existing dbt project with some models and tests
- Understanding of your data warehouse schema structure

### Installation Options

#### Option 1: Install from GitHub (Recommended)
```yaml
# packages.yml
packages:
  - git: https://github.com/your-org/dbt-test-results.git
    revision: v1.0.0
```

#### Option 2: Install from dbt Hub
```yaml
# packages.yml
packages:
  - package: your-org/dbt_test_results
    version: [">=1.0.0", "<2.0.0"]
```

**After adding to packages.yml:**
```bash
dbt deps
```

### Configuration Deep Dive

#### Basic Configuration
```yaml
# dbt_project.yml - Minimal setup
vars:
  dbt_test_results:
    enabled: true  # Enable the package
```

#### Enhanced Configuration
```yaml
# dbt_project.yml - More control
vars:
  dbt_test_results:
    enabled: true
    
    # Storage configuration
    schema_suffix: "_test_results"  # Custom schema naming
    
    # Performance settings
    batch_size: 1000              # Tests processed per batch
    
    # Data retention
    retention_days: 90            # Keep 90 days of history
    
    # Metadata capture
    capture_git_info: true        # Include git commit info
    capture_user_info: true       # Include execution user
    
    # Error handling
    fail_on_error: false          # Don't break builds on package errors
    debug_mode: false             # Enable for troubleshooting
```

### Model Configuration Patterns

#### Single Model Setup
```yaml
# models/schema.yml
models:
  - name: customers
    config:
      store_test_results: "customer_test_history"
    tests:
      - unique:
          column_name: customer_id
      - not_null:
          column_name: customer_id
    columns:
      - name: email
        tests:
          - unique
          - not_null
```

#### Multiple Models, Shared Results Table
```yaml
# models/schema.yml
models:
  - name: customers
    config:
      store_test_results: "core_data_quality_tests"
    # ... tests ...
  
  - name: orders
    config:
      store_test_results: "core_data_quality_tests"
    # ... tests ...
  
  - name: products
    config:
      store_test_results: "core_data_quality_tests"
    # ... tests ...
```

#### Domain-Specific Results Tables
```yaml
# models/schema.yml
models:
  # Customer domain
  - name: customers
    config:
      store_test_results: "customer_domain_tests"
  
  - name: customer_segments
    config:
      store_test_results: "customer_domain_tests"
  
  # Finance domain
  - name: orders
    config:
      store_test_results: "finance_domain_tests"
  
  - name: payments
    config:
      store_test_results: "finance_domain_tests"
```

---

## 📊 Understanding Your Test Results

### Test Results Table Schema

Each test results table contains these columns:

| Column | Description | Example |
|--------|-------------|----------|
| `execution_timestamp` | When the test ran | `2024-12-27 14:30:52` |
| `model_name` | Model being tested | `customers` |
| `test_name` | Full test name | `unique_customers_customer_id` |
| `test_type` | Type of test | `unique`, `not_null`, `custom` |
| `status` | Test outcome | `pass`, `fail`, `error`, `skip` |
| `failures` | Number of failing records | `0` (pass) or `5` (fail) |
| `execution_time_seconds` | How long test took | `2.34` |
| `message` | Error or summary message | `Found 3 null email values` |
| `metadata` | Additional context (JSON) | Git info, user, environment |

### Basic Queries to Get Started

#### 1. Recent Test Results
```sql
-- See your most recent test results
SELECT 
  execution_timestamp,
  model_name,
  test_type,
  status,
  failures,
  execution_time_seconds
FROM your_schema.customer_test_history
ORDER BY execution_timestamp DESC
LIMIT 20;
```

#### 2. Test Success Rate
```sql
-- Calculate overall test success rate
SELECT 
  COUNT(*) as total_tests,
  SUM(CASE WHEN status = 'pass' THEN 1 ELSE 0 END) as passed_tests,
  ROUND(100.0 * SUM(CASE WHEN status = 'pass' THEN 1 ELSE 0 END) / COUNT(*), 2) as success_rate_pct
FROM your_schema.customer_test_history
WHERE execution_timestamp >= CURRENT_DATE - 7;  -- Last 7 days
```

#### 3. Slowest Tests
```sql
-- Find your slowest tests for optimization
SELECT 
  test_name,
  model_name,
  AVG(execution_time_seconds) as avg_duration,
  COUNT(*) as execution_count
FROM your_schema.customer_test_history
WHERE execution_timestamp >= CURRENT_DATE - 30
GROUP BY test_name, model_name
ORDER BY avg_duration DESC
LIMIT 10;
```

#### 4. Daily Test Trends
```sql
-- Track test success over time
SELECT 
  DATE(execution_timestamp) as test_date,
  COUNT(*) as total_tests,
  SUM(CASE WHEN status = 'pass' THEN 1 ELSE 0 END) as passed_tests,
  SUM(CASE WHEN status = 'fail' THEN 1 ELSE 0 END) as failed_tests,
  ROUND(100.0 * SUM(CASE WHEN status = 'pass' THEN 1 ELSE 0 END) / COUNT(*), 2) as success_rate_pct
FROM your_schema.customer_test_history
WHERE execution_timestamp >= CURRENT_DATE - 30
GROUP BY DATE(execution_timestamp)
ORDER BY test_date DESC;
```

---

## 🚀 Expanding to Your Full Project

### Step 1: Identify High-Value Models

Start with models that are:
- **Business critical**: Used in key reports or decisions
- **Frequently accessed**: High query volume
- **Data quality sensitive**: Customer-facing or regulatory
- **Integration points**: Between different data sources

### Step 2: Choose Results Table Strategy

**Option A: Single Central Table**
```yaml
# All models use one results table
store_test_results: "enterprise_data_quality_tests"
```
- ✅ Simple to query and analyze
- ✅ Easy to create overall quality dashboards
- ⚠️ Can become large with many models

**Option B: Domain-Based Tables**
```yaml
# Group by business domain
store_test_results: "customer_domain_tests"  # Customer models
store_test_results: "finance_domain_tests"   # Finance models
store_test_results: "product_domain_tests"   # Product models
```
- ✅ Better organization and access control
- ✅ Easier to manage retention policies per domain
- ⚠️ Requires more complex cross-domain analysis

**Option C: Model-Specific Tables**
```yaml
# Each important model gets its own table
store_test_results: "customers_test_history"
store_test_results: "orders_test_history"
```
- ✅ Maximum isolation and control
- ✅ Easy to grant specific access
- ⚠️ Many tables to manage

### Step 3: Gradual Rollout Plan

**Week 1-2: Core Models**
- Add 3-5 most critical models
- Test the setup and queries
- Train team on basic usage

**Week 3-4: Domain Expansion**
- Add all models in one business domain
- Create domain-specific dashboards
- Establish monitoring routines

**Week 5-6: Full Deployment**
- Add remaining models
- Implement performance monitoring
- Create enterprise dashboards

### Step 4: Team Training

**For Analysts:**
- How to query test results
- Building data quality dashboards
- Interpreting trends and patterns

**For Engineers:**
- Configuration best practices
- Performance optimization
- Troubleshooting common issues

**For Managers:**
- Reading data quality reports
- Understanding business impact
- Setting quality thresholds

---

## 📈 Measuring Success

### Key Metrics to Track

1. **Test Coverage**: % of critical models with test result tracking
2. **Test Success Rate**: % of tests passing over time
3. **Response Time**: How quickly you detect and fix data quality issues
4. **Team Usage**: How often team members query test results
5. **Business Impact**: Reduction in data quality incidents

### Setting Up Monitoring

#### Daily Quality Check
```sql
-- Daily data quality summary
SELECT 
  'Daily Quality Summary' as report_type,
  CURRENT_DATE as report_date,
  COUNT(*) as total_tests_today,
  SUM(CASE WHEN status = 'fail' THEN 1 ELSE 0 END) as failed_tests,
  CASE 
    WHEN SUM(CASE WHEN status = 'fail' THEN 1 ELSE 0 END) = 0 THEN '✅ All tests passing'
    WHEN SUM(CASE WHEN status = 'fail' THEN 1 ELSE 0 END) <= 3 THEN '⚠️ Minor issues detected'
    ELSE '🚨 Multiple test failures'
  END as status_summary
FROM your_schema.enterprise_data_quality_tests
WHERE DATE(execution_timestamp) = CURRENT_DATE;
```

#### Weekly Trend Analysis
```sql
-- Weekly quality trends
WITH weekly_stats AS (
  SELECT 
    DATE_TRUNC('week', execution_timestamp) as week_start,
    COUNT(*) as total_tests,
    AVG(CASE WHEN status = 'pass' THEN 1.0 ELSE 0.0 END) as success_rate,
    AVG(execution_time_seconds) as avg_execution_time
  FROM your_schema.enterprise_data_quality_tests
  WHERE execution_timestamp >= CURRENT_DATE - 28  -- Last 4 weeks
  GROUP BY DATE_TRUNC('week', execution_timestamp)
)
SELECT 
  week_start,
  total_tests,
  ROUND(success_rate * 100, 1) as success_rate_pct,
  ROUND(avg_execution_time, 2) as avg_execution_time_sec,
  CASE 
    WHEN success_rate >= 0.95 THEN '✅ Excellent'
    WHEN success_rate >= 0.90 THEN '✅ Good'
    WHEN success_rate >= 0.80 THEN '⚠️ Needs attention'
    ELSE '🚨 Poor quality'
  END as quality_grade
FROM weekly_stats
ORDER BY week_start DESC;
```

---

## 🎉 Next Steps

Once you have basic test result tracking working:

1. **📊 Build Dashboards**: Create BI tool dashboards using the queries above
2. **🔔 Set Up Alerts**: Configure notifications for test failures
3. **📈 Performance Tuning**: Optimize test execution and storage
4. **🤝 Team Training**: Get your team using test results for daily work
5. **🔄 Continuous Improvement**: Regularly review and enhance your setup

### Helpful Resources

- **[Use Cases & Examples](docs/USE_CASES.md)**: Real-world implementation patterns
- **[Troubleshooting Guide](docs/TROUBLESHOOTING.md)**: Common issues and solutions
- **[Performance Optimization](docs/PERFORMANCE.md)**: Scale to large test suites
- **[Advanced Configuration](examples/advanced/)**: Enterprise-grade setups
- **[Community Support](https://github.com/your-org/dbt-test-results/discussions)**: Ask questions and share experiences

---

## 🆘 Need Help?

### Quick Support
- **🐛 Found a bug?** [Report it here](https://github.com/your-org/dbt-test-results/issues/new?template=bug_report.yml)
- **💡 Feature idea?** [Suggest it here](https://github.com/your-org/dbt-test-results/issues/new?template=feature_request.yml)
- **❓ Have questions?** [Ask in discussions](https://github.com/your-org/dbt-test-results/discussions)
- **💬 Real-time help?** Join [dbt Community Slack](https://getdbt.slack.com) #package-ecosystem

### Common "Getting Started" Issues

**"Package not found"**
- Check your `packages.yml` syntax
- Ensure you've run `dbt deps`
- Verify the package version exists

**"Tests not being captured"**
- Confirm `enabled: true` in dbt_project.yml
- Check that `store_test_results` is in your model config
- Verify your schema allows table creation

**"Performance seems slow"**
- Start with smaller batch sizes
- See [Performance Guide](docs/PERFORMANCE.md)
- Check your database adapter optimizations

---

**🎯 Remember: Start small, iterate quickly, and expand gradually. The goal is to build sustainable data quality monitoring that your team actually uses!**