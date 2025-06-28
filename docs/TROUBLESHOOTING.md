# Troubleshooting Guide

## 🎯 Quick Diagnostic Tools

### 🔍 Health Check Command

Run this command to diagnose common issues:

```bash
# Enable debug mode and run a single test
dbt test --models your_model_name --vars '{dbt_test_results: {debug_mode: true}}'
```

Look for these debug messages:
- `dbt-test-results: Package enabled and configured`
- `dbt-test-results: Creating results table [table_name]`
- `dbt-test-results: Storing [X] test results`

---

## 🚨 Common Issues and Solutions

### 1. Package Not Working / Tests Not Being Captured

#### 🔴 **Symptom**: No test results are being stored, no errors shown

**🔍 Diagnostic Steps:**
```bash
# Check if package is enabled
dbt run-operation check_package_status

# Run test with debug mode
dbt test --models your_model --vars '{dbt_test_results: {debug_mode: true}}'

# Check if results table exists
# Replace 'your_schema' with your actual schema
SELECT * FROM your_schema.your_test_results_table LIMIT 1;
```

**✅ Solutions:**

1. **Enable the package** in `dbt_project.yml`:
   ```yaml
   vars:
     dbt_test_results:
       enabled: true  # ← Must be explicitly set
   ```

2. **Add model configuration** in `schema.yml`:
   ```yaml
   models:
     - name: your_model
       config:
         store_test_results: "your_test_history"  # ← Required
   ```

3. **Check dependencies** in `packages.yml`:
   ```yaml
   packages:
     - git: https://github.com/your-org/dbt-test-results.git
       revision: v1.0.0
     - package: dbt-labs/dbt_utils  # ← Required dependency
       version: [">=0.8.0", "<2.0.0"]
   ```
   Then run: `dbt deps`

4. **Verify schema permissions**:
   ```sql
   -- Test if you can create tables in your schema
   CREATE TABLE your_schema.test_permissions_check (id INT);
   DROP TABLE your_schema.test_permissions_check;
   ```

---

### 2. Permission / Schema Errors

#### 🔴 **Symptom**: `Permission denied` or `Schema does not exist` errors

**Error Messages:**
```
Database Error in macro store_test_results
  permission denied for schema your_schema
```

**✅ Solutions:**

1. **Grant schema permissions**:
   ```sql
   -- For Snowflake
   GRANT CREATE TABLE ON SCHEMA your_schema TO ROLE your_role;
   GRANT USAGE ON SCHEMA your_schema TO ROLE your_role;
   
   -- For BigQuery
   -- Ensure your service account has BigQuery Data Editor role
   
   -- For Databricks
   GRANT CREATE TABLE ON SCHEMA your_schema TO `your_user@company.com`;
   ```

2. **Use a different schema**:
   ```yaml
   vars:
     dbt_test_results:
       enabled: true
       absolute_schema: "data_quality_results"  # Custom schema
   ```

3. **Use schema suffix approach**:
   ```yaml
   vars:
     dbt_test_results:
       enabled: true
       schema_suffix: "_test_results"  # Appends to target schema
   ```

4. **Check your profiles.yml**:
   ```yaml
   your_project:
     target: dev
     outputs:
       dev:
         # ... your connection details ...
         schema: your_schema  # ← Ensure this schema exists
   ```

---

### 3. Performance Issues / Slow Tests

#### 🔴 **Symptom**: dbt tests running much slower after adding package

**🔍 Diagnostic Steps:**
```sql
-- Check test execution times
SELECT 
  test_name,
  model_name,
  AVG(execution_time_seconds) as avg_duration,
  MAX(execution_time_seconds) as max_duration,
  COUNT(*) as execution_count
FROM your_schema.your_test_history
WHERE execution_timestamp >= CURRENT_DATE - 7
GROUP BY 1, 2
ORDER BY avg_duration DESC
LIMIT 10;
```

**✅ Solutions:**

1. **Optimize batch size**:
   ```yaml
   vars:
     dbt_test_results:
       enabled: true
       batch_size: 5000  # Start high, reduce if memory issues
   ```

2. **Enable parallel processing**:
   ```yaml
   vars:
     dbt_test_results:
       enabled: true
       enable_parallel_processing: true
       batch_size: 3000  # Smaller batches with parallel processing
   ```

3. **Reduce metadata capture**:
   ```yaml
   vars:
     dbt_test_results:
       enabled: true
       capture_git_info: false      # Saves ~0.5s per test
       capture_user_info: false     # Saves ~0.2s per test
       include_model_config: false  # Saves ~0.3s per test
   ```

4. **Use adapter-specific optimizations**:
   ```yaml
   # For Snowflake
   vars:
     dbt_test_results:
       use_merge_strategy: true
       enable_clustering: true
       cluster_by: ["execution_timestamp", "model_name"]
   
   # For BigQuery
   vars:
     dbt_test_results:
       enable_clustering: true
       partition_by: "DATE(execution_timestamp)"
   
   # For Databricks
   vars:
     dbt_test_results:
       file_format: "delta"
       use_merge_strategy: true
   ```

5. **Implement selective testing**:
   ```yaml
   # Only track critical models
   models:
     - name: critical_model_1
       config:
         store_test_results: "critical_tests_only"
     - name: non_critical_model
       # No store_test_results = no tracking
   ```

---

### 4. Memory / Resource Issues

#### 🔴 **Symptom**: Out of memory errors, connection timeouts

**Error Messages:**
```
MemoryError: Unable to allocate array
Connection timeout
dbt-core OutOfMemoryError
```

**✅ Solutions:**

1. **Reduce batch size**:
   ```yaml
   vars:
     dbt_test_results:
       enabled: true
       batch_size: 1000  # Start small
       memory_limit_mb: 2048  # Set memory limit
   ```

2. **Enable memory management**:
   ```yaml
   vars:
     dbt_test_results:
       enabled: true
       enable_memory_management: true
       memory_threshold_mb: 1500  # Alert before limit
   ```

3. **Use streaming mode for large test suites**:
   ```yaml
   vars:
     dbt_test_results:
       enabled: true
       streaming_mode: true      # Process tests one at a time
       batch_size: 500          # Small batches
   ```

4. **Implement retention cleanup**:
   ```yaml
   vars:
     dbt_test_results:
       enabled: true
       retention_days: 30       # Shorter retention
       auto_cleanup_enabled: true
       cleanup_frequency_days: 7
   ```

---

### 5. Configuration Issues

#### 🔴 **Symptom**: Package behavior not matching configuration

**🔍 Diagnostic Steps:**
```bash
# Check effective configuration
dbt run-operation print_test_results_config

# Validate configuration syntax
dbt parse
```

**✅ Solutions:**

1. **Check YAML syntax**:
   ```yaml
   # ❌ Wrong (missing quotes)
   vars:
     dbt_test_results:
       enabled: true
       schema_suffix: _test_results  # Missing quotes
   
   # ✅ Correct
   vars:
     dbt_test_results:
       enabled: true
       schema_suffix: "_test_results"  # Quoted string
   ```

2. **Verify variable precedence**:
   ```yaml
   # dbt_project.yml (lowest priority)
   vars:
     dbt_test_results:
       enabled: true
   
   # Command line (highest priority)
   # dbt test --vars '{dbt_test_results: {enabled: false}}'
   ```

3. **Check target-specific configuration**:
   ```yaml
   # Can vary by environment
   vars:
     dbt_test_results:
       enabled: "{{ true if target.name == 'prod' else false }}"
   ```

---

### 6. Adapter-Specific Issues

#### 🔴 **BigQuery Issues**

**Common Error:**
```
BadRequest: Syntax error: Expected "(" or keyword SELECT
```

**✅ Solutions:**
```yaml
vars:
  dbt_test_results:
    enabled: true
    # BigQuery-specific settings
    enable_clustering: true
    cluster_by: ["model_name", "test_type"]
    partition_by: "DATE(execution_timestamp)"
    table_properties:
      partition_expiration_days: 365
```

#### 🔴 **Snowflake Issues**

**Common Error:**
```
SQL compilation error: Object does not exist
```

**✅ Solutions:**
```yaml
vars:
  dbt_test_results:
    enabled: true
    # Snowflake-specific settings
    enable_clustering: true
    cluster_by: ["execution_timestamp", "model_name"]
    table_properties:
      automatic_clustering: true
```

#### 🔴 **Databricks Issues**

**Common Error:**
```
AnalysisException: MERGE destination only supports Delta sources
```

**✅ Solutions:**
```yaml
vars:
  dbt_test_results:
    enabled: true
    # Databricks-specific settings
    file_format: "delta"
    use_merge_strategy: true
    table_properties:
      delta.autoOptimize.optimizeWrite: true
      delta.autoOptimize.autoCompact: true
```

#### 🔴 **PostgreSQL Issues**

**Common Error:**
```
psycopg2.errors.UndefinedTable: relation "test_results" does not exist
```

**✅ Solutions:**
```yaml
vars:
  dbt_test_results:
    enabled: true
    # PostgreSQL-specific settings
    enable_indexing: true
    index_columns: ["execution_timestamp", "model_name"]
```

---

### 7. Data Issues / Incorrect Results

#### 🔴 **Symptom**: Test results seem wrong or inconsistent

**🔍 Diagnostic Steps:**
```sql
-- Check for duplicate results
SELECT 
  execution_timestamp,
  test_name,
  COUNT(*) as duplicate_count
FROM your_schema.your_test_history
GROUP BY 1, 2
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- Verify recent test results
SELECT 
  execution_timestamp,
  model_name,
  test_name,
  status,
  failures,
  message
FROM your_schema.your_test_history
WHERE execution_timestamp >= CURRENT_TIMESTAMP - INTERVAL '1 hour'
ORDER BY execution_timestamp DESC;
```

**✅ Solutions:**

1. **Check for timezone issues**:
   ```yaml
   vars:
     dbt_test_results:
       enabled: true
       timezone: "UTC"  # Explicit timezone
   ```

2. **Verify test execution context**:
   ```yaml
   vars:
     dbt_test_results:
       enabled: true
       capture_git_info: true   # Track code versions
       capture_user_info: true  # Track execution context
   ```

3. **Enable data validation**:
   ```yaml
   vars:
     dbt_test_results:
       enabled: true
       validate_results: true   # Extra validation
       debug_mode: true        # Verbose logging
   ```

---

## 🚑 Emergency Procedures

### 🚨 **Emergency: Package Breaking Production Builds**

**Immediate Action:**
```yaml
# Disable package immediately
vars:
  dbt_test_results:
    enabled: false  # Quick disable
```

**Or remove from specific models:**
```yaml
models:
  - name: critical_model
    config:
      # store_test_results: "table_name"  # Comment out
```

**Run tests to confirm:**
```bash
dbt test --models critical_model
```

### 🚨 **Emergency: High Resource Usage**

**Immediate Resource Reduction:**
```yaml
vars:
  dbt_test_results:
    enabled: true
    batch_size: 100              # Minimal batches
    capture_git_info: false      # Reduce overhead
    capture_user_info: false
    include_model_config: false
    debug_mode: false
```

### 🚨 **Emergency: Data Quality Crisis**

**Quick Quality Assessment:**
```sql
-- Immediate quality overview
SELECT 
  'CRITICAL QUALITY ASSESSMENT' as report_type,
  COUNT(*) as total_tests_last_hour,
  SUM(CASE WHEN status = 'fail' THEN 1 ELSE 0 END) as failed_tests,
  SUM(CASE WHEN status = 'error' THEN 1 ELSE 0 END) as error_tests,
  STRING_AGG(
    CASE WHEN status IN ('fail', 'error') 
    THEN CONCAT(model_name, ':', test_name) 
    END, ', '
  ) as failing_tests
FROM your_schema.your_test_history
WHERE execution_timestamp >= CURRENT_TIMESTAMP - INTERVAL '1 hour';
```

---

## 🔧 Advanced Diagnostics

### System Information Collection

```bash
#!/bin/bash
# diagnostics.sh - Collect system information

echo "=== dbt-test-results Diagnostics ==="
echo "Date: $(date)"
echo ""

echo "=== dbt Version ==="
dbt --version
echo ""

echo "=== Package Dependencies ==="
cat packages.yml
echo ""

echo "=== Configuration ==="
dbt run-operation print_test_results_config 2>/dev/null || echo "Config check failed"
echo ""

echo "=== Recent Logs ==="
tail -n 20 logs/dbt.log 2>/dev/null || echo "No recent logs found"
echo ""

echo "=== Database Connection ==="
dbt debug --connection
echo ""

echo "=== Test Results Tables ==="
# Replace with your actual schema
dbt run-operation query --args "SELECT table_name, row_count FROM information_schema.tables WHERE table_name LIKE '%test%'"
```

### Performance Profiling

```sql
-- Performance analysis query
WITH test_performance AS (
  SELECT 
    model_name,
    test_type,
    COUNT(*) as execution_count,
    AVG(execution_time_seconds) as avg_duration,
    STDDEV(execution_time_seconds) as duration_stddev,
    MIN(execution_time_seconds) as min_duration,
    MAX(execution_time_seconds) as max_duration,
    SUM(execution_time_seconds) as total_time
  FROM your_schema.your_test_history
  WHERE execution_timestamp >= CURRENT_DATE - 7
  GROUP BY 1, 2
)
SELECT 
  *,
  CASE 
    WHEN avg_duration > 60 THEN 'SLOW'
    WHEN avg_duration > 30 THEN 'MODERATE'
    ELSE 'FAST'
  END as performance_category,
  
  CASE 
    WHEN duration_stddev > avg_duration * 0.5 THEN 'INCONSISTENT'
    ELSE 'CONSISTENT'
  END as consistency_rating
FROM test_performance
ORDER BY total_time DESC;
```

---

## 📞 Getting Additional Help

### 🔴 **Still Having Issues?**

1. **Search existing issues**: [GitHub Issues](https://github.com/your-org/dbt-test-results/issues)

2. **Create a detailed bug report**: [Bug Report Template](https://github.com/your-org/dbt-test-results/issues/new?template=bug_report.yml)

3. **Join community discussion**: [GitHub Discussions](https://github.com/your-org/dbt-test-results/discussions)

4. **Real-time help**: [dbt Community Slack](https://getdbt.slack.com) #package-ecosystem

### 📦 **Information to Include in Bug Reports**

```yaml
# Please include this information:
Environment:
  dbt_version: "1.7.4"
  adapter: "snowflake"
  package_version: "v1.0.0"
  python_version: "3.9.0"
  os: "Ubuntu 20.04"

Configuration:
  # Your dbt_project.yml vars section
  # Your schema.yml model config
  # Any custom macros

Error:
  # Full error message
  # dbt logs with debug mode enabled
  # Steps to reproduce
```

### 🐛 **Common "Not a Bug" Issues**

- **"Tests are slow"**: This is expected with large test suites. See performance optimization guide.
- **"Results table is large"**: Implement retention policies and cleanup procedures.
- **"Different results on different runs"**: Check for non-deterministic tests or timezone issues.
- **"Package doesn't work with custom tests"**: Custom test integration requires specific patterns.

---

## 📄 Troubleshooting Checklist

### ✅ **Before Asking for Help**

- [ ] Enabled package in `dbt_project.yml`
- [ ] Added `store_test_results` to model configuration
- [ ] Ran `dbt deps` after adding package
- [ ] Tested with debug mode enabled
- [ ] Checked database permissions
- [ ] Reviewed error logs carefully
- [ ] Searched existing issues and documentation
- [ ] Tried with minimal configuration first
- [ ] Verified adapter compatibility
- [ ] Tested with sample data

### ✅ **Information to Gather**

- [ ] dbt version and adapter type
- [ ] Package version
- [ ] Complete error message
- [ ] Configuration (sanitized)
- [ ] Steps to reproduce
- [ ] Expected vs. actual behavior
- [ ] Environment details
- [ ] Sample data (if relevant)

---

**🎆 Remember: Most issues are configuration-related and can be resolved quickly with the right diagnostic approach. Don't hesitate to ask for help with specific details about your setup!**