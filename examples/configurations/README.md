# Configuration Examples

This directory contains environment-specific configuration examples for the dbt-test-results package. These templates help you optimize the package for different deployment scenarios and organizational needs.

## 📁 Available Configurations

### **development.yml** 🛠️
Development-friendly settings for fast iteration and debugging:
- Lower batch sizes for quick feedback
- Debug mode enabled for troubleshooting
- Shorter retention periods to save storage
- Non-failing error handling for experimentation

**Best for:** Local development, feature testing, debugging

### **production.yml** 🚀  
Production-optimized settings for reliability and performance:
- Large batch sizes for efficiency
- Strict error handling and monitoring
- Extended retention for compliance
- Performance optimization enabled

**Best for:** Production deployments, enterprise environments

### **monitoring.yml** 📊
Monitoring-focused configuration for observability:
- Health check automation enabled
- Performance logging and alerts
- Rich metadata capture
- Dashboard-friendly data structure

**Best for:** Data quality monitoring, compliance reporting, analytics

## 🎯 Choosing the Right Configuration

| Environment | Recommended Config | Key Benefits |
|-------------|-------------------|--------------|
| **Local Development** | development.yml | Fast feedback, easy debugging |
| **CI/CD Pipeline** | development.yml | Quick validation, non-blocking |
| **Staging/QA** | production.yml | Production parity, full testing |
| **Production** | production.yml | Reliability, performance, compliance |
| **Data Quality Dashboard** | monitoring.yml | Rich metrics, alerting, reporting |

## 🚀 Quick Usage

### 1. **Copy Configuration Template**
```bash
# Copy the desired configuration
cp examples/configurations/production.yml your-project/dbt_project.yml

# Or merge with your existing project
cat examples/configurations/production.yml >> your-project/dbt_project.yml
```

### 2. **Customize for Your Environment**
Edit the copied configuration to match your specific needs:
- Update schema names and prefixes
- Adjust batch sizes based on your data volume
- Set appropriate retention periods
- Configure adapter-specific optimizations

### 3. **Validate Configuration**
```bash
# Test your configuration
dbt run-operation dbt_test_results.validate_configuration

# Run a test build
dbt build --select test_type:data
```

## ⚙️ Configuration Details

### **Development Configuration Highlights**
```yaml
vars:
  dbt_test_results:
    # Fast feedback for development
    batch_size: 500
    debug_mode: true
    fail_on_error: false
    
    # Short retention for local testing
    retention_days: 7
    auto_cleanup_enabled: true
    
    # Development-friendly naming
    schema_suffix: "_dev_test_results"
    table_prefix: "dev_"
```

### **Production Configuration Highlights**  
```yaml
vars:
  dbt_test_results:
    # Production performance optimization
    batch_size: 5000
    enable_parallel_processing: true
    use_merge_strategy: true
    
    # Enterprise data management
    retention_days: 365
    capture_git_info: true
    capture_user_info: true
    
    # Strict production settings
    fail_on_error: true
    debug_mode: false
```

### **Monitoring Configuration Highlights**
```yaml
vars:
  dbt_test_results:
    # Rich monitoring capabilities
    enable_performance_logging: true
    enable_health_checks: true
    include_model_config: true
    include_column_info: true
    
    # Dashboard optimizations
    absolute_schema: "data_quality_monitoring"
    capture_execution_metadata: true
```

## 🔧 Customization Guide

### **Environment Variables Support**
All configurations support environment variable overrides:

```yaml
vars:
  dbt_test_results:
    # Use environment variables for sensitive values
    schema_suffix: "{{ env_var('DBT_TEST_RESULTS_SCHEMA_SUFFIX', '_test_results') }}"
    batch_size: "{{ env_var('DBT_TEST_RESULTS_BATCH_SIZE', '1000') | int }}"
    retention_days: "{{ env_var('DBT_TEST_RESULTS_RETENTION_DAYS', '90') | int }}"
```

### **Adapter-Specific Customizations**

#### **For Databricks/Spark**
```yaml
vars:
  dbt_test_results:
    batch_size: 10000  # Higher batch sizes work well
    use_merge_strategy: true  # Leverage Delta Lake MERGE
    table_properties:
      delta.autoOptimize.optimizeWrite: true
      delta.autoOptimize.autoCompact: true
```

#### **For BigQuery**
```yaml
vars:
  dbt_test_results:
    batch_size: 25000  # BigQuery handles large batches well
    enable_clustering: true
    partition_by: "DATE(execution_timestamp)"
    table_properties:
      partition_expiration_days: 365
```

#### **For Snowflake**
```yaml
vars:
  dbt_test_results:
    batch_size: 15000  # Optimal for Snowflake's architecture
    enable_clustering: true
    table_properties:
      automatic_clustering: true
      data_retention_time_in_days: 90
```

### **Multi-Environment Setup**
Use dbt profiles for environment-specific configurations:

```yaml
# profiles.yml
your_project:
  outputs:
    dev:
      # Development settings
      vars:
        dbt_test_results:
          batch_size: 500
          debug_mode: true
    
    prod:
      # Production settings  
      vars:
        dbt_test_results:
          batch_size: 5000
          fail_on_error: true
```

## 📊 Configuration Impact

### **Performance Considerations**

| Setting | Development | Production | Impact |
|---------|-------------|------------|--------|
| `batch_size` | 500 | 5000+ | Higher = faster processing, more memory |
| `parallel_processing` | false | true | Improves speed but increases complexity |
| `debug_mode` | true | false | Detailed logs but slower execution |
| `retention_days` | 7 | 365+ | Storage cost vs historical data needs |

### **Resource Requirements**

| Configuration | Memory Usage | Storage Growth | Query Performance |
|---------------|--------------|----------------|-------------------|
| Development | Low | Minimal | Fast (small data) |
| Production | Medium-High | Significant | Optimized |
| Monitoring | Medium | High | Dashboard-optimized |

## 🚨 Common Configuration Issues

### **Memory Problems**
```yaml
# If you see memory errors, reduce batch size
vars:
  dbt_test_results:
    batch_size: 1000  # Reduce from higher values
    memory_limit_mb: 2048  # Set explicit limit
```

### **Performance Issues**
```yaml
# If processing is slow, optimize for your adapter
vars:
  dbt_test_results:
    enable_parallel_processing: true
    use_merge_strategy: true  # For Delta/Iceberg tables
    batch_size: 5000  # Increase if memory allows
```

### **Storage Issues**
```yaml
# If tables grow too large, implement cleanup
vars:
  dbt_test_results:
    retention_days: 30  # Reduce retention
    auto_cleanup_enabled: true
    cleanup_frequency_days: 7
```

## 🔄 Migration Between Configurations

When changing configurations:

1. **Backup existing data** before major changes
2. **Test in staging** environment first
3. **Monitor performance** after changes
4. **Update documentation** and team processes

```bash
# Backup before migration
dbt run-operation dbt_test_results.backup_results --args '{backup_suffix: _pre_migration}'

# Apply new configuration
dbt run

# Validate migration
dbt run-operation dbt_test_results.validate_configuration
```

## 📋 Configuration Checklist

Before deploying a configuration:

- [ ] **Performance requirements** meet your data volume needs
- [ ] **Retention period** aligns with compliance requirements  
- [ ] **Schema naming** follows organizational standards
- [ ] **Error handling** appropriate for environment (strict vs permissive)
- [ ] **Monitoring settings** match observability needs
- [ ] **Resource limits** tested under expected load
- [ ] **Backup strategy** in place for configuration changes

## 📞 Support

For configuration assistance:
- **Review documentation** in main README for detailed explanations
- **Check troubleshooting** guides in specific example directories
- **Test configurations** thoroughly in non-production environments
- **Monitor performance** after deployment and adjust as needed

---

*These configuration examples provide tested patterns for common deployment scenarios. Customize them based on your specific requirements and infrastructure constraints.*