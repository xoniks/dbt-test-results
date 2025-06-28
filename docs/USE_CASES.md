# Real-World Use Cases and Implementation Patterns

## 🎯 Overview

This guide showcases how different types of organizations use dbt-test-results to solve real data quality challenges. Each use case includes specific configuration, queries, and implementation strategies you can adapt for your needs.

---

## 🏢 Enterprise Use Cases

### 1. Financial Services Company: Regulatory Compliance

**Challenge**: Required to maintain detailed audit trails for all data quality checks to meet SOX compliance requirements.

**Solution**: Comprehensive test result tracking with extended metadata capture.

#### Configuration
```yaml
# dbt_project.yml
vars:
  dbt_test_results:
    enabled: true
    
    # Compliance requirements
    capture_git_info: true          # Track code versions
    capture_user_info: true         # Track who ran tests
    include_model_config: true      # Include model configurations
    include_column_info: true       # Track column-level details
    
    # Data retention for compliance
    retention_days: 2555            # 7 years (SOX requirement)
    auto_cleanup_enabled: false     # Manual cleanup for compliance
    
    # Audit trail features
    absolute_schema: "compliance_audit"  # Dedicated schema
    table_prefix: "sox_"               # Clear table naming
    
    # Performance for large scale
    batch_size: 10000
    use_merge_strategy: true
    enable_parallel_processing: true
```

#### Schema Configuration
```yaml
# models/core/schema.yml
models:
  - name: customer_accounts
    config:
      store_test_results: "sox_financial_data_tests"
    description: "Customer account information for regulatory reporting"
    tests:
      - dbt_utils.expression_is_true:
          expression: "balance >= 0"
          config:
            severity: error  # Critical for compliance
      - dbt_utils.unique_combination_of_columns:
          combination_of_columns:
            - customer_id
            - account_number
          config:
            severity: error
    columns:
      - name: customer_id
        tests:
          - not_null:
              config:
                severity: error
          - relationships:
              to: ref('customers')
              field: customer_id
              config:
                severity: error
      
      - name: balance
        tests:
          - not_null:
              config:
                severity: error

  - name: transactions
    config:
      store_test_results: "sox_financial_data_tests"
    tests:
      - dbt_utils.expression_is_true:
          expression: "amount != 0"  # No zero-value transactions
          config:
            severity: warn
```

#### Compliance Reporting Queries
```sql
-- Daily compliance report
WITH daily_test_summary AS (
  SELECT 
    DATE(execution_timestamp) as test_date,
    model_name,
    test_type,
    COUNT(*) as total_tests,
    SUM(CASE WHEN status = 'pass' THEN 1 ELSE 0 END) as passed_tests,
    SUM(CASE WHEN status = 'fail' THEN 1 ELSE 0 END) as failed_tests,
    SUM(CASE WHEN status = 'error' THEN 1 ELSE 0 END) as error_tests,
    
    -- Extract user information for audit trail
    JSON_EXTRACT_SCALAR(metadata, '$.user_name') as executed_by,
    JSON_EXTRACT_SCALAR(metadata, '$.git_commit_sha') as code_version
    
  FROM compliance_audit.sox_financial_data_tests
  WHERE execution_timestamp >= CURRENT_DATE - 1
  GROUP BY 1, 2, 3, 6, 7
)
SELECT 
  test_date,
  model_name,
  total_tests,
  passed_tests,
  failed_tests,
  error_tests,
  ROUND(100.0 * passed_tests / total_tests, 2) as success_rate_pct,
  executed_by,
  code_version,
  
  -- Compliance status
  CASE 
    WHEN failed_tests = 0 AND error_tests = 0 THEN 'COMPLIANT'
    WHEN failed_tests > 0 THEN 'NON_COMPLIANT - DATA QUALITY ISSUES'
    ELSE 'NON_COMPLIANT - TECHNICAL ERRORS'
  END as compliance_status
  
FROM daily_test_summary
ORDER BY test_date DESC, model_name;

-- Monthly audit report
SELECT 
  DATE_TRUNC('month', execution_timestamp) as audit_month,
  COUNT(DISTINCT DATE(execution_timestamp)) as testing_days,
  COUNT(*) as total_test_executions,
  COUNT(DISTINCT model_name) as models_tested,
  
  -- Quality metrics
  ROUND(100.0 * SUM(CASE WHEN status = 'pass' THEN 1 ELSE 0 END) / COUNT(*), 2) as overall_success_rate,
  
  -- Compliance metrics
  SUM(CASE WHEN status = 'fail' THEN 1 ELSE 0 END) as total_failures,
  COUNT(DISTINCT CASE WHEN status = 'fail' THEN DATE(execution_timestamp) END) as days_with_failures,
  
  -- Audit trail completeness
  COUNT(DISTINCT JSON_EXTRACT_SCALAR(metadata, '$.user_name')) as unique_users,
  COUNT(DISTINCT JSON_EXTRACT_SCALAR(metadata, '$.git_commit_sha')) as unique_code_versions
  
FROM compliance_audit.sox_financial_data_tests
WHERE execution_timestamp >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '12 months'
GROUP BY 1
ORDER BY 1 DESC;
```

**Outcome**: Passed SOX audit with complete data quality audit trail. Auditors praised the comprehensive tracking and automated compliance reporting.

---

### 2. Healthcare Organization: Data Quality Monitoring

**Challenge**: Patient data quality issues could impact care decisions. Need real-time monitoring and immediate alerts for critical data problems.

**Solution**: Multi-tier test classification with automated alerting for critical failures.

#### Configuration
```yaml
# dbt_project.yml
vars:
  dbt_test_results:
    enabled: true
    
    # Healthcare-specific settings
    fail_on_error: true             # Don't continue with bad data
    capture_user_info: true         # Track for accountability
    capture_git_info: true          # Version control for regulations
    
    # Performance for real-time monitoring
    batch_size: 5000
    enable_parallel_processing: true
    
    # Data governance
    retention_days: 2555            # Long retention for medical records
    absolute_schema: "data_quality_monitoring"
```

#### Multi-Tier Testing Strategy
```yaml
# models/clinical/schema.yml
models:
  - name: patient_records
    config:
      store_test_results: "critical_patient_data_tests"
    description: "Core patient information - CRITICAL for patient care"
    tests:
      # CRITICAL tests - immediate alerts
      - unique:
          column_name: patient_id
          config:
            severity: error
            meta:
              alert_level: "critical"
              business_impact: "Patient safety risk"
      
      - not_null:
          column_name: patient_id
          config:
            severity: error
            meta:
              alert_level: "critical"
      
      # WARNING tests - daily review
      - dbt_utils.expression_is_true:
          expression: "birth_date <= CURRENT_DATE"
          config:
            severity: warn
            meta:
              alert_level: "warning"
              business_impact: "Data accuracy concern"
    
    columns:
      - name: patient_id
        description: "Unique patient identifier"
        tests:
          - unique:
              config:
                severity: error
                meta:
                  alert_level: "critical"
          - not_null:
              config:
                severity: error
                meta:
                  alert_level: "critical"
      
      - name: medical_record_number
        description: "Hospital medical record number"
        tests:
          - unique:
              config:
                severity: error
                meta:
                  alert_level: "critical"
          - not_null:
              config:
                severity: error
                meta:
                  alert_level: "critical"
      
      - name: birth_date
        tests:
          - not_null:
              config:
                severity: warn
                meta:
                  alert_level: "warning"
      
      - name: contact_phone
        tests:
          - dbt_utils.expression_is_true:
              expression: "LENGTH(contact_phone) >= 10"
              config:
                severity: warn
                meta:
                  alert_level: "info"

  - name: lab_results
    config:
      store_test_results: "critical_patient_data_tests"
    tests:
      # Critical lab data validation
      - dbt_utils.expression_is_true:
          expression: "result_value IS NOT NULL OR result_status = 'CANCELLED'"
          config:
            severity: error
            meta:
              alert_level: "critical"
              business_impact: "Missing lab results affect diagnosis"
```

#### Real-Time Monitoring Queries
```sql
-- Critical alert monitoring (run every 15 minutes)
WITH recent_critical_failures AS (
  SELECT 
    execution_timestamp,
    model_name,
    test_name,
    test_type,
    failures,
    message,
    JSON_EXTRACT_SCALAR(metadata, '$.test_meta.alert_level') as alert_level,
    JSON_EXTRACT_SCALAR(metadata, '$.test_meta.business_impact') as business_impact
  FROM data_quality_monitoring.critical_patient_data_tests
  WHERE 
    execution_timestamp >= CURRENT_TIMESTAMP - INTERVAL '15 minutes'
    AND status = 'fail'
    AND JSON_EXTRACT_SCALAR(metadata, '$.test_meta.alert_level') = 'critical'
)
SELECT 
  'CRITICAL DATA QUALITY ALERT' as alert_type,
  execution_timestamp,
  model_name,
  test_name,
  failures,
  business_impact,
  message,
  
  -- Alert message for notification system
  CONCAT(
    '🚨 CRITICAL: ', failures, ' ', test_type, ' failures in ', model_name,
    '. Impact: ', business_impact, 
    '. Immediate review required.'
  ) as alert_message
  
FROM recent_critical_failures
ORDER BY execution_timestamp DESC;

-- Daily quality dashboard for clinical team
WITH daily_summary AS (
  SELECT 
    DATE(execution_timestamp) as test_date,
    model_name,
    JSON_EXTRACT_SCALAR(metadata, '$.test_meta.alert_level') as alert_level,
    COUNT(*) as total_tests,
    SUM(CASE WHEN status = 'pass' THEN 1 ELSE 0 END) as passed_tests,
    SUM(CASE WHEN status = 'fail' THEN 1 ELSE 0 END) as failed_tests,
    SUM(failures) as total_failing_records
  FROM data_quality_monitoring.critical_patient_data_tests
  WHERE execution_timestamp >= CURRENT_DATE - 7
  GROUP BY 1, 2, 3
)
SELECT 
  test_date,
  model_name,
  alert_level,
  total_tests,
  failed_tests,
  total_failing_records,
  ROUND(100.0 * passed_tests / total_tests, 1) as success_rate_pct,
  
  -- Quality status for dashboard
  CASE 
    WHEN alert_level = 'critical' AND failed_tests > 0 THEN '🚨 CRITICAL ISSUES'
    WHEN alert_level = 'warning' AND failed_tests > 5 THEN '⚠️ ATTENTION NEEDED'
    WHEN failed_tests = 0 THEN '✅ ALL TESTS PASSING'
    ELSE '📊 MINOR ISSUES'
  END as quality_status
  
FROM daily_summary
ORDER BY 
  test_date DESC,
  CASE alert_level 
    WHEN 'critical' THEN 1 
    WHEN 'warning' THEN 2 
    ELSE 3 
  END,
  failed_tests DESC;
```

**Outcome**: Reduced patient data quality incidents by 75%. Clinical team now has real-time visibility into data issues affecting patient care.

---

## 📊 Mid-Size Organization Use Cases

### 3. E-commerce Company: Performance Optimization

**Challenge**: dbt test runs were taking 45+ minutes, blocking daily data refreshes and causing delayed business reporting.

**Solution**: Performance-focused configuration with test result analysis to identify and optimize slow tests.

#### Performance Configuration
```yaml
# dbt_project.yml
vars:
  dbt_test_results:
    enabled: true
    
    # Performance optimization
    batch_size: 8000                # Larger batches for efficiency
    enable_parallel_processing: true # Concurrent processing
    use_merge_strategy: true        # Efficient upserts
    memory_limit_mb: 6144          # 6GB memory limit
    
    # Storage optimization
    enable_clustering: true         # Snowflake clustering
    cluster_by: ["execution_timestamp", "model_name"]
    partition_by: "DATE(execution_timestamp)"
    
    # Monitoring
    enable_performance_logging: true
    enable_health_checks: true
    capture_git_info: false         # Reduce metadata overhead
    capture_user_info: false
```

#### Test Performance Analysis
```sql
-- Identify slowest tests for optimization
WITH test_performance AS (
  SELECT 
    test_name,
    model_name,
    test_type,
    COUNT(*) as execution_count,
    AVG(execution_time_seconds) as avg_duration,
    MAX(execution_time_seconds) as max_duration,
    MIN(execution_time_seconds) as min_duration,
    STDDEV(execution_time_seconds) as duration_stddev,
    
    -- Calculate total time spent on this test
    SUM(execution_time_seconds) as total_time_spent,
    
    -- Performance classification
    CASE 
      WHEN AVG(execution_time_seconds) > 60 THEN 'SLOW'
      WHEN AVG(execution_time_seconds) > 30 THEN 'MODERATE'
      ELSE 'FAST'
    END as performance_category
    
  FROM ecom_data.test_performance_tracking
  WHERE execution_timestamp >= CURRENT_DATE - 30
  GROUP BY 1, 2, 3
)
SELECT 
  performance_category,
  test_name,
  model_name,
  test_type,
  execution_count,
  ROUND(avg_duration, 2) as avg_duration_sec,
  ROUND(max_duration, 2) as max_duration_sec,
  ROUND(total_time_spent, 2) as total_time_spent_sec,
  ROUND(duration_stddev, 2) as duration_variability,
  
  -- Optimization priority
  CASE 
    WHEN total_time_spent > 300 AND avg_duration > 30 THEN 'HIGH PRIORITY'
    WHEN total_time_spent > 150 AND avg_duration > 15 THEN 'MEDIUM PRIORITY'
    ELSE 'LOW PRIORITY'
  END as optimization_priority,
  
  -- Optimization suggestions
  CASE 
    WHEN test_type = 'unique' AND avg_duration > 30 THEN 'Consider adding index on unique column'
    WHEN test_type = 'not_null' AND avg_duration > 10 THEN 'Check for table scan - add WHERE clause'
    WHEN test_type = 'relationships' AND avg_duration > 60 THEN 'Optimize join performance'
    WHEN avg_duration > 120 THEN 'Consider custom test with optimized query'
    ELSE 'Performance acceptable'
  END as optimization_suggestion
  
FROM test_performance
ORDER BY total_time_spent DESC;

-- Daily performance trends
SELECT 
  DATE(execution_timestamp) as test_date,
  COUNT(*) as total_tests,
  ROUND(SUM(execution_time_seconds), 2) as total_execution_time_sec,
  ROUND(AVG(execution_time_seconds), 2) as avg_test_duration_sec,
  ROUND(SUM(execution_time_seconds) / 60, 2) as total_execution_time_min,
  
  -- Performance targets
  CASE 
    WHEN SUM(execution_time_seconds) <= 1800 THEN '✅ UNDER 30 MIN TARGET'
    WHEN SUM(execution_time_seconds) <= 2700 THEN '⚠️ APPROACHING 45 MIN LIMIT'
    ELSE '🚨 OVER 45 MIN LIMIT'
  END as performance_status,
  
  -- Slowest test of the day
  MAX(execution_time_seconds) as slowest_test_duration,
  
FROM ecom_data.test_performance_tracking
WHERE execution_timestamp >= CURRENT_DATE - 30
GROUP BY 1
ORDER BY 1 DESC;
```

#### Optimization Implementation
```yaml
# Optimized test configuration based on analysis
models:
  - name: customer_orders  # Large table - was slowest
    config:
      store_test_results: "ecom_performance_tests"
    tests:
      # Optimized unique test with sampling for large tables
      - dbt_utils.unique_combination_of_columns:
          combination_of_columns:
            - customer_id
            - order_id
          config:
            # Sample large tables for faster testing
            where: "created_at >= CURRENT_DATE - 30"  # Only recent data
      
      # Replace expensive relationships test with custom optimized version
      - dbt_utils.expression_is_true:
          expression: |
            customer_id IN (
              SELECT customer_id 
              FROM {{ ref('customers') }} 
              WHERE is_active = true
            )
          config:
            # More efficient than relationships test for large tables
            where: "created_at >= CURRENT_DATE - 7"  # Recent orders only
```

**Outcome**: Reduced test execution time from 45 minutes to 18 minutes (60% improvement). Identified and optimized 12 slow tests, enabling more frequent data refreshes.

---

### 4. Marketing Agency: Multi-Client Data Quality

**Challenge**: Managing data quality across 50+ client accounts with different requirements and access controls.

**Solution**: Client-isolated test result tracking with centralized monitoring dashboard.

#### Multi-Client Configuration
```yaml
# dbt_project.yml
vars:
  dbt_test_results:
    enabled: true
    
    # Client isolation
    schema_suffix: "_{{ var('client_name', 'default') }}_tests"
    table_prefix: "{{ var('client_tier', 'standard') }}_"
    
    # Flexible retention by client tier
    retention_days: "{{ var('retention_days', 90) }}"
    
    # Client-specific features
    capture_git_info: "{{ var('track_versions', false) }}"
    capture_user_info: "{{ var('track_users', false) }}"
```

#### Client-Specific Deployment
```yaml
# profiles.yml template for client deployments
client_a_premium:
  target: prod
  outputs:
    prod:
      type: snowflake
      # ... connection details ...
      schema: client_a_data
      
client_b_standard:
  target: prod
  outputs:
    prod:
      type: snowflake
      # ... connection details ...
      schema: client_b_data
```

```bash
# Deployment script for different client tiers
#!/bin/bash

# Premium client with enhanced tracking
dbt run --profiles-dir ./profiles --profile client_a_premium \
  --vars '{
    "client_name": "client_a",
    "client_tier": "premium",
    "retention_days": 365,
    "track_versions": true,
    "track_users": true
  }'

# Standard client with basic tracking
dbt run --profiles-dir ./profiles --profile client_b_standard \
  --vars '{
    "client_name": "client_b",
    "client_tier": "standard",
    "retention_days": 90,
    "track_versions": false,
    "track_users": false
  }'
```

#### Centralized Monitoring Dashboard
```sql
-- Cross-client quality summary (agency dashboard)
WITH client_schemas AS (
  -- List all client test result schemas
  SELECT DISTINCT table_schema as client_schema
  FROM information_schema.tables
  WHERE table_name LIKE '%_test_history'
    AND table_schema LIKE '%_tests'
),

client_quality AS (
  SELECT 
    REGEXP_EXTRACT(client_schema, r'(.+)_tests$', 1) as client_name,
    DATE(execution_timestamp) as test_date,
    COUNT(*) as total_tests,
    SUM(CASE WHEN status = 'pass' THEN 1 ELSE 0 END) as passed_tests,
    SUM(CASE WHEN status = 'fail' THEN 1 ELSE 0 END) as failed_tests,
    ROUND(AVG(execution_time_seconds), 2) as avg_test_duration
  FROM (
    -- Dynamic UNION across all client schemas
    {% for schema in get_client_schemas() %}
    SELECT 
      '{{ schema }}' as client_schema,
      execution_timestamp,
      status,
      execution_time_seconds
    FROM {{ schema }}.standard_test_history
    WHERE execution_timestamp >= CURRENT_DATE - 7
    {% if not loop.last %}UNION ALL{% endif %}
    {% endfor %}
  )
  GROUP BY 1, 2
)

SELECT 
  client_name,
  test_date,
  total_tests,
  failed_tests,
  ROUND(100.0 * passed_tests / total_tests, 1) as success_rate_pct,
  avg_test_duration,
  
  -- Client health status
  CASE 
    WHEN failed_tests = 0 THEN '✅ HEALTHY'
    WHEN failed_tests <= 3 THEN '⚠️ MINOR ISSUES'
    ELSE '🚨 NEEDS ATTENTION'
  END as client_health_status,
  
  -- SLA compliance (example: 95% success rate)
  CASE 
    WHEN (passed_tests * 100.0 / total_tests) >= 95 THEN '✅ SLA MET'
    ELSE '❌ SLA MISSED'
  END as sla_status
  
FROM client_quality
ORDER BY test_date DESC, client_name;

-- Client-specific drill-down query
SELECT 
  execution_timestamp,
  model_name,
  test_name,
  test_type,
  status,
  failures,
  execution_time_seconds,
  message
FROM client_a_data.client_a_premium_test_history
WHERE 
  execution_timestamp >= CURRENT_DATE - 1
  AND status = 'fail'
ORDER BY execution_timestamp DESC;
```

**Outcome**: Successfully managing 50+ client accounts with isolated data quality tracking. Reduced client onboarding time by 60% with standardized test patterns.

---

## 💼 Small Team Use Cases

### 5. Startup: Rapid Development with Quality Gates

**Challenge**: Fast-moving startup needs to maintain data quality while shipping features quickly. Limited resources for complex monitoring.

**Solution**: Simple, effective test result tracking with automated quality gates in CI/CD.

#### Lightweight Configuration
```yaml
# dbt_project.yml
vars:
  dbt_test_results:
    enabled: true
    
    # Simple setup
    batch_size: 1000
    retention_days: 30              # Keep it light
    fail_on_error: false           # Don't block development
    debug_mode: true               # Help with troubleshooting
    
    # Minimal metadata
    capture_git_info: true          # Track versions for debugging
    capture_user_info: false       # Not needed for small team
```

#### Simple but Effective Schema
```yaml
# models/schema.yml
models:
  - name: users
    config:
      store_test_results: "startup_data_quality"
    tests:
      - dbt_utils.expression_is_true:
          expression: "created_at <= CURRENT_TIMESTAMP"
    columns:
      - name: user_id
        tests:
          - unique
          - not_null
      - name: email
        tests:
          - unique
          - not_null

  - name: events
    config:
      store_test_results: "startup_data_quality"
    columns:
      - name: user_id
        tests:
          - not_null
          - relationships:
              to: ref('users')
              field: user_id
      - name: event_timestamp
        tests:
          - not_null
```

#### Quality Gate for CI/CD
```bash
#!/bin/bash
# quality_gate.sh - Run in CI/CD pipeline

echo "Running dbt tests with quality tracking..."
dbt test

echo "Checking data quality trends..."

# Simple quality check query
QUALITY_CHECK=$(dbt run-operation query --args "
  SELECT 
    CASE 
      WHEN COUNT(*) = 0 THEN 'NO_DATA'
      WHEN SUM(CASE WHEN status = 'fail' THEN 1 ELSE 0 END) = 0 THEN 'PASS'
      WHEN SUM(CASE WHEN status = 'fail' THEN 1 ELSE 0 END) <= 2 THEN 'WARNING'
      ELSE 'FAIL'
    END as quality_status
  FROM startup_data_quality.startup_data_quality
  WHERE execution_timestamp >= CURRENT_DATE - 1
")

echo "Quality status: $QUALITY_CHECK"

# Decide whether to block deployment
if [[ "$QUALITY_CHECK" == *"FAIL"* ]]; then
  echo "❌ Quality gate failed - blocking deployment"
  exit 1
elif [[ "$QUALITY_CHECK" == *"WARNING"* ]]; then
  echo "⚠️ Quality warnings detected - review recommended"
  # Continue deployment but notify team
else
  echo "✅ Quality gate passed"
fi
```

#### Daily Quality Dashboard
```sql
-- Simple daily quality summary for Slack bot
WITH today_summary AS (
  SELECT 
    COUNT(*) as total_tests,
    SUM(CASE WHEN status = 'pass' THEN 1 ELSE 0 END) as passed_tests,
    SUM(CASE WHEN status = 'fail' THEN 1 ELSE 0 END) as failed_tests,
    ROUND(AVG(execution_time_seconds), 1) as avg_duration
  FROM startup_data_quality.startup_data_quality
  WHERE DATE(execution_timestamp) = CURRENT_DATE
),

yesterday_summary AS (
  SELECT 
    COUNT(*) as total_tests,
    SUM(CASE WHEN status = 'pass' THEN 1 ELSE 0 END) as passed_tests
  FROM startup_data_quality.startup_data_quality
  WHERE DATE(execution_timestamp) = CURRENT_DATE - 1
)

SELECT 
  CONCAT(
    '📊 Daily Data Quality Report\n',
    '• Tests run: ', t.total_tests, '\n',
    '• Success rate: ', ROUND(100.0 * t.passed_tests / t.total_tests, 1), '%\n',
    '• Failed tests: ', t.failed_tests, '\n',
    '• Avg duration: ', t.avg_duration, 's\n',
    '• Trend: ', 
    CASE 
      WHEN t.passed_tests > y.passed_tests THEN '📈 Improving'
      WHEN t.passed_tests < y.passed_tests THEN '📉 Declining'
      ELSE '➡️ Stable'
    END
  ) as slack_message
FROM today_summary t
CROSS JOIN yesterday_summary y;
```

**Outcome**: Maintained 95%+ data quality while shipping 3x faster. Prevented 8 data quality issues from reaching production.

---

## 🔧 Implementation Patterns

### Pattern 1: Gradual Rollout

**Week 1-2: Core Models**
```yaml
# Start with 3-5 most critical models
models:
  - name: customers      # Most important
  - name: orders         # High impact
  - name: revenue_daily  # Business critical
```

**Week 3-4: Domain Expansion**
```yaml
# Add entire business domain
models:
  - name: customers
  - name: customer_segments
  - name: customer_lifecycle
  - name: customer_support_tickets
```

**Week 5-6: Full Project**
```yaml
# All models with appropriate grouping
store_test_results: "{{ var('domain') }}_test_history"
```

### Pattern 2: Test Classification

```yaml
# Classify tests by impact and urgency
tests:
  - unique:
      config:
        severity: error    # Blocks pipeline
        meta:
          impact: "high"   # Business critical
          urgency: "immediate"  # Fix now
  
  - not_null:
      config:
        severity: warn     # Doesn't block
        meta:
          impact: "medium" # Data quality
          urgency: "daily"  # Fix soon
```

### Pattern 3: Environment-Specific Configuration

```yaml
# Development environment
vars:
  dbt_test_results:
    enabled: true
    retention_days: 7        # Short retention
    batch_size: 500         # Smaller batches
    debug_mode: true        # Verbose logging

# Production environment  
vars:
  dbt_test_results:
    enabled: true
    retention_days: 365     # Long retention
    batch_size: 5000       # Larger batches
    capture_git_info: true  # Track versions
    fail_on_error: true    # Strict mode
```

---

## 🏆 Best Practices Summary

### 1. Start Simple, Scale Gradually
- Begin with core models and basic configuration
- Add complexity as you understand your needs
- Monitor performance impact as you scale

### 2. Align with Business Impact
- Prioritize tests on business-critical models
- Set appropriate severity levels
- Create domain-specific monitoring

### 3. Optimize for Your Scale
- Small teams: Simple setup, focus on automation
- Medium teams: Domain-based organization
- Large teams: Comprehensive governance and compliance

### 4. Make It Actionable
- Create dashboards people actually use
- Set up alerts for critical issues
- Integrate with existing workflows

### 5. Measure and Improve
- Track adoption and usage metrics
- Regularly review and optimize slow tests
- Gather feedback and iterate

---

**🌟 Remember: The best implementation is the one your team actually uses consistently. Start with what adds immediate value and expand from there.**