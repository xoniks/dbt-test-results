# Advanced dbt-test-results Configuration

This example demonstrates advanced configuration patterns for the dbt-test-results package, suitable for production environments with complex requirements.

## 🎯 Use Cases

This advanced configuration is ideal for:
- **Enterprise environments** with multiple teams and projects
- **Production deployments** with high test volumes
- **Multi-environment setups** with different retention policies  
- **Complex data pipelines** with custom test result storage needs
- **Organizations requiring** audit trails and compliance

## 📋 Key Features Demonstrated

### 1. **Enterprise Schema Management**
- Centralized test results storage across all models
- Custom table naming with organizational prefixes
- Environment-specific schema segregation

### 2. **Advanced Performance Optimization**
- Large batch processing for high-volume test suites
- Memory management and parallel processing
- Adapter-specific optimizations

### 3. **Production Data Management**
- Extended retention periods for compliance
- Automated cleanup and archival strategies
- Rich metadata capture for audit trails

### 4. **Error Handling & Monitoring**
- Production-grade error handling with retries
- Comprehensive logging and alerting
- Performance monitoring and health checks

## ⚙️ Configuration Breakdown

### **Core Production Settings**
```yaml
vars:
  dbt_test_results:
    # Production safety
    enabled: true
    debug_mode: false
    fail_on_error: true  # Strict error handling
    
    # Centralized storage
    absolute_schema: "data_quality_central"
    table_prefix: "org_"
```

### **Performance Optimization**
```yaml
    # High-volume processing
    batch_size: 5000
    enable_parallel_processing: true
    use_merge_strategy: true
    memory_limit_mb: 4096
```

### **Enterprise Data Management**
```yaml
    # Extended retention for compliance
    retention_days: 365
    auto_cleanup_enabled: true
    
    # Rich metadata for audit trails
    capture_git_info: true
    capture_user_info: true
    include_model_config: true
    include_column_info: true
```

### **Monitoring & Alerts**
```yaml
    # Production monitoring
    enable_performance_logging: true
    enable_health_checks: true
    alert_on_failures: true
    performance_threshold_seconds: 300
```

## 🏗️ Advanced Schema Configuration

### **Shared Results Table Strategy**
This example uses a centralized table for all test results, providing:
- **Unified reporting** across all models and tests
- **Simplified monitoring** with single table queries
- **Cost optimization** by reducing table sprawl
- **Enhanced analytics** with cross-model test insights

```yaml
models:
  - name: customer_data
    config:
      store_test_results: "enterprise_test_results"
      
  - name: order_data  
    config:
      store_test_results: "enterprise_test_results"
      
  - name: financial_data
    config:
      store_test_results: "enterprise_test_results"
```

### **Test Result Schema**
The centralized table includes enterprise-grade metadata:

| Column | Description | Example |
|--------|-------------|---------|
| `organization_unit` | Team/department identifier | "data_engineering" |
| `environment` | Deployment environment | "production" |
| `git_commit_sha` | Source code version | "a1b2c3d4" |
| `execution_user` | Person/service running tests | "data-pipeline-svc" |
| `compliance_tags` | Regulatory/audit tags | ["PII", "GDPR"] |

## 🚀 Quick Start

### 1. **Copy Configuration**
```bash
# Copy the advanced example to your project
cp -r examples/advanced/* your-dbt-project/
```

### 2. **Customize for Your Organization**
Edit `dbt_project.yml` variables:
```yaml
vars:
  dbt_test_results:
    # Update these for your environment
    absolute_schema: "your_org_data_quality"
    table_prefix: "yourorg_"
    organization_unit: "your_team_name"
```

### 3. **Run Initial Setup**
```bash
# Install package dependencies
dbt deps

# Create the centralized test results table
dbt run-operation dbt_test_results.create_results_table --args '{table_name: enterprise_test_results}'

# Run your models and tests
dbt build
```

### 4. **Verify Results**
```sql
-- Check test results are being captured
SELECT 
  model_name,
  test_type,
  status,
  execution_timestamp,
  organization_unit
FROM your_org_data_quality.enterprise_test_results
ORDER BY execution_timestamp DESC
LIMIT 10;
```

## 📊 Enterprise Reporting Examples

### **Data Quality Dashboard Query**
```sql
WITH test_summary AS (
  SELECT 
    DATE(execution_timestamp) as test_date,
    organization_unit,
    model_name,
    COUNT(*) as total_tests,
    SUM(CASE WHEN status = 'pass' THEN 1 ELSE 0 END) as passed_tests,
    SUM(CASE WHEN status = 'fail' THEN 1 ELSE 0 END) as failed_tests,
    SUM(CASE WHEN status = 'error' THEN 1 ELSE 0 END) as error_tests
  FROM {{ var('dbt_test_results')['absolute_schema'] }}.enterprise_test_results
  WHERE execution_timestamp >= CURRENT_DATE - 30
  GROUP BY 1, 2, 3
)
SELECT 
  test_date,
  organization_unit,
  COUNT(DISTINCT model_name) as models_tested,
  SUM(total_tests) as total_tests,
  ROUND(100.0 * SUM(passed_tests) / SUM(total_tests), 2) as pass_rate_pct,
  SUM(failed_tests) as total_failures
FROM test_summary
GROUP BY 1, 2
ORDER BY 1 DESC, 2;
```

### **Compliance Audit Trail**
```sql
SELECT 
  execution_timestamp,
  model_name,
  test_name,
  test_type,
  status,
  git_commit_sha,
  execution_user,
  compliance_tags,
  error_message
FROM {{ var('dbt_test_results')['absolute_schema'] }}.enterprise_test_results
WHERE 'PII' = ANY(compliance_tags)
  AND execution_timestamp >= CURRENT_DATE - 90
ORDER BY execution_timestamp DESC;
```

## 🔧 Production Deployment

### **Environment-Specific Configurations**

#### **Development Environment**
```yaml
vars:
  dbt_test_results:
    absolute_schema: "dev_data_quality"
    retention_days: 30
    batch_size: 1000
    debug_mode: true
    fail_on_error: false
```

#### **Staging Environment**  
```yaml
vars:
  dbt_test_results:
    absolute_schema: "staging_data_quality"
    retention_days: 90
    batch_size: 2500
    debug_mode: false
    fail_on_error: true
```

#### **Production Environment**
```yaml
vars:
  dbt_test_results:
    absolute_schema: "prod_data_quality"
    retention_days: 365
    batch_size: 5000
    debug_mode: false
    fail_on_error: true
    enable_health_checks: true
```

## 🚨 Monitoring & Alerting

### **Performance Monitoring**
Set up automated monitoring for:
- **Test execution duration** > 5 minutes
- **Batch processing failures** or timeouts
- **Memory usage** exceeding configured limits
- **Table growth** beyond expected rates

### **Health Check Queries**
```sql
-- Daily health check
SELECT 
  'test_results_health' as check_name,
  CASE 
    WHEN COUNT(*) = 0 THEN 'FAIL: No test results today'
    WHEN MAX(execution_timestamp) < CURRENT_TIMESTAMP - INTERVAL '6 hours' THEN 'WARN: Stale test results'
    ELSE 'PASS: Recent test results found'
  END as status,
  COUNT(*) as test_count_today,
  MAX(execution_timestamp) as latest_execution
FROM {{ var('dbt_test_results')['absolute_schema'] }}.enterprise_test_results
WHERE DATE(execution_timestamp) = CURRENT_DATE;
```

## 🔐 Security & Compliance

### **Access Control**
```sql
-- Grant read access to analysts
GRANT SELECT ON {{ var('dbt_test_results')['absolute_schema'] }}.enterprise_test_results 
TO ROLE analyst_role;

-- Grant write access to dbt service account
GRANT INSERT, UPDATE, DELETE ON {{ var('dbt_test_results')['absolute_schema'] }}.enterprise_test_results 
TO ROLE dbt_service_role;
```

### **Data Retention Policy**
The package automatically handles data retention based on `retention_days`. For additional compliance:

```sql
-- Manual archive for regulatory requirements
CREATE TABLE {{ var('dbt_test_results')['absolute_schema'] }}.enterprise_test_results_archive_2024
AS SELECT * FROM {{ var('dbt_test_results')['absolute_schema'] }}.enterprise_test_results
WHERE YEAR(execution_timestamp) = 2024;
```

## 📈 Scaling Considerations

### **High-Volume Environments (>10k tests/day)**
- Increase `batch_size` to 10000+
- Enable `use_merge_strategy: true`
- Consider table partitioning by date
- Monitor memory usage and adjust limits

### **Multi-Region Deployments**
- Use separate schemas per region
- Configure region-specific retention policies
- Set up cross-region replication if needed

### **Cost Optimization**
- Use table clustering on frequently queried columns
- Implement automated archival to cheaper storage tiers
- Monitor query costs and optimize dashboard queries

## 🆘 Troubleshooting

### **Common Production Issues**

#### **Performance Degradation**
```bash
# Check batch size and memory settings
dbt run-operation dbt_test_results.validate_configuration

# Monitor execution times
dbt run-operation dbt_test_results.generate_performance_report
```

#### **Storage Growth**
```sql
-- Check table size growth
SELECT 
  DATE(execution_timestamp) as test_date,
  COUNT(*) as daily_test_count,
  SUM(COUNT(*)) OVER (ORDER BY DATE(execution_timestamp)) as cumulative_tests
FROM enterprise_test_results
GROUP BY 1
ORDER BY 1 DESC
LIMIT 30;
```

#### **Error Investigation**
```sql
-- Recent errors for investigation
SELECT 
  execution_timestamp,
  model_name,
  test_name,
  error_message,
  git_commit_sha
FROM enterprise_test_results
WHERE status = 'error'
  AND execution_timestamp >= CURRENT_TIMESTAMP - INTERVAL '24 hours'
ORDER BY execution_timestamp DESC;
```

## 🔄 Migration from Basic Setup

If upgrading from a basic dbt-test-results setup:

1. **Backup existing data**
2. **Update configuration** to use centralized schema
3. **Migrate historical data** if needed
4. **Update reporting queries** to new schema structure
5. **Test thoroughly** in staging environment

## 📞 Support

For advanced configuration support:
- **Performance tuning** guidance in our documentation
- **Custom implementation** examples in the GitHub repository
- **Community support** via GitHub Discussions
- **Enterprise support** contact information in main README

---

*This advanced configuration provides enterprise-grade test result management with comprehensive monitoring, compliance features, and production-ready performance optimization.*