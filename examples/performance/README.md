# Performance Benchmarking Examples

This directory contains comprehensive performance benchmarking tools and examples for the dbt-test-results package. Use these examples to optimize your package configuration and measure performance across different scenarios.

## 📁 Directory Structure

```
examples/performance/
├── README.md                 # This documentation
├── dbt_project.yml          # Performance-optimized configuration
├── run_benchmarks.sh        # Automated benchmarking script
└── models/
    ├── large_dataset.sql     # 10k records for volume testing
    ├── order_data.sql        # Multi-model testing data
    ├── inventory_data.sql    # Multi-model testing data
    └── schema.yml           # Comprehensive test configurations
```

## 🚀 Quick Start

1. **Navigate to the performance examples directory:**
   ```bash
   cd examples/performance
   ```

2. **Configure your database connection** in `profiles.yml` or environment variables

3. **Run the automated benchmarks:**
   ```bash
   chmod +x run_benchmarks.sh
   ./run_benchmarks.sh
   ```

4. **Review results** in the generated CSV and log files

## 🏗️ Benchmark Scenarios

### Volume Testing
- **Model:** `large_dataset` (10,000 records)
- **Tests:** 15 comprehensive data quality tests
- **Focus:** Raw volume handling and batch processing efficiency

### Multi-Model Testing
- **Models:** `order_data` + `inventory_data` 
- **Configuration:** Shared results table
- **Focus:** Concurrent test execution and table contention

### Custom Test Performance
- **Custom tests:** Email uniqueness, data quality summary, business rules
- **Focus:** Complex SQL execution and custom test overhead

### Batch Size Optimization
- **Scenarios:** 100, 1,000, 5,000, 10,000 record batches
- **Focus:** Finding optimal batch size for your environment

## 📊 Understanding Results

### CSV Output Format
```csv
run_number,scenario,operation,duration_seconds,records_processed,throughput_per_second,memory_estimate_mb,batch_size,success
1,large_batch,complete,45.32,15,0.33,10.24,5000,true
```

### Key Metrics
- **Duration:** Total execution time in seconds
- **Throughput:** Tests processed per second
- **Memory Estimate:** Approximate memory usage in MB
- **Success Rate:** Percentage of successful runs

### Performance Analysis
The script automatically analyzes results and provides:
- 🏆 Best performing configuration
- 📊 Average duration by batch size
- 💾 Memory usage patterns
- ✅ Success rate statistics

## ⚙️ Configuration Options

### Batch Size Tuning
```yaml
vars:
  dbt_test_results:
    batch_size: 5000  # Adjust based on benchmark results
```

### Performance Optimizations
```yaml
vars:
  dbt_test_results:
    enable_parallel_processing: true
    use_merge_strategy: true
    enable_performance_logging: true
    memory_limit_mb: 2048
```

### Adapter-Specific Settings

#### Databricks/Spark
```yaml
vars:
  dbt_test_results:
    batch_size: 10000
    use_merge_strategy: true
    enable_parallel_processing: true
```

#### BigQuery
```yaml
vars:
  dbt_test_results:
    batch_size: 25000
    enable_clustering: true
    partition_by: "DATE(execution_timestamp)"
```

#### Snowflake
```yaml
vars:
  dbt_test_results:
    batch_size: 15000
    enable_clustering: true
    warehouse_size: "MEDIUM"
```

## 🔧 Customizing Benchmarks

### Adding New Test Scenarios

1. **Create new model file:**
   ```sql
   -- models/your_scenario.sql
   {{ config(materialized='table') }}
   
   SELECT * FROM your_test_data
   ```

2. **Add tests in schema.yml:**
   ```yaml
   models:
     - name: your_scenario
       config:
         store_test_results: "your_scenario_tests"
       tests:
         - your_custom_tests
   ```

3. **Update run_benchmarks.sh:**
   ```bash
   # Add new scenario
   run_benchmark "your_scenario" 2000 "your_custom_vars: true"
   ```

### Modifying Data Volume

Edit `large_dataset.sql` to change record count:
```sql
-- Change this line to adjust volume
WHERE id <= 50000  -- Increase to 50k records
```

### Custom Performance Metrics

Add custom tracking in your tests:
```sql
-- Custom test with performance tracking
SELECT 
  COUNT(*) as issues_found,
  '{{ run_started_at }}' as benchmark_timestamp
FROM {{ ref('your_model') }}
WHERE your_condition
```

## 📈 Performance Recommendations

### Based on Adapter Type

#### Spark/Databricks
- **Optimal batch size:** 5,000-25,000
- **Memory allocation:** 4-8GB per executor
- **Parallelization:** Enable for datasets >10k tests

#### BigQuery
- **Optimal batch size:** 10,000-50,000  
- **Clustering:** Use (model_name, test_type, status)
- **Partitioning:** By DATE(execution_timestamp)

#### Snowflake
- **Optimal batch size:** 5,000-25,000
- **Warehouse sizing:** MEDIUM for <100k tests, LARGE for >100k
- **Clustering:** Use (execution_timestamp, model_name)

### General Guidelines

1. **Start small:** Begin with batch_size: 1000
2. **Monitor memory:** Watch for OOM errors as you scale
3. **Test incrementally:** Increase batch size by 2-5x per test
4. **Profile queries:** Use your adapter's query profiling tools
5. **Consider concurrency:** Multiple dbt runs may affect performance

## 🚨 Troubleshooting

### Common Issues

#### Memory Errors
```bash
# Reduce batch size
dbt run --vars '{dbt_test_results: {batch_size: 500}}'
```

#### Timeout Errors  
```bash
# Increase timeout and reduce parallelism
dbt run --vars '{dbt_test_results: {enable_parallel_processing: false}}'
```

#### Connection Limits
```bash
# Reduce concurrent connections
dbt run --threads 2
```

### Performance Debugging

Enable debug mode for detailed logging:
```yaml
vars:
  dbt_test_results:
    debug_mode: true
    enable_performance_logging: true
```

Check execution plans in your database:
```sql
-- Example for analyzing slow queries
EXPLAIN SELECT * FROM your_test_results_table 
WHERE execution_timestamp > CURRENT_DATE - 1
```

## 📋 Benchmark Checklist

Before running benchmarks:
- [ ] Database connection verified (`dbt debug`)
- [ ] Sufficient database resources allocated
- [ ] No concurrent heavy workloads running
- [ ] Baseline performance metrics captured
- [ ] Monitoring tools enabled (if available)

After benchmarks:
- [ ] Results reviewed and analyzed
- [ ] Optimal configuration identified
- [ ] Production settings updated
- [ ] Performance regression tests established
- [ ] Documentation updated with findings

## 🔄 Continuous Performance Testing

### Integration with CI/CD

Add to your GitHub Actions workflow:
```yaml
- name: Performance Benchmark
  run: |
    cd examples/performance
    ./run_benchmarks.sh
    # Upload results to monitoring system
```

### Regular Monitoring

Set up periodic benchmarks:
```bash
# Cron job for weekly performance checks
0 2 * * 0 cd /path/to/performance && ./run_benchmarks.sh
```

### Performance Regression Detection

Compare results over time:
```bash
# Compare with baseline
python compare_benchmark_results.py baseline.csv current.csv
```

## 🤝 Contributing

To improve these benchmarking examples:

1. **Add new scenarios** for edge cases or specific use patterns
2. **Enhance analysis** with additional metrics or visualizations  
3. **Optimize scripts** for better cross-platform compatibility
4. **Document findings** from real-world performance testing

## 📞 Support

If you encounter issues with performance benchmarking:

1. **Check logs** in the generated benchmark files
2. **Review adapter documentation** for platform-specific optimizations
3. **Open an issue** with benchmark results and system specifications
4. **Share findings** to help improve the package for everyone

---

*Remember: Performance is highly dependent on your specific database platform, data volume, and infrastructure. Use these benchmarks as a starting point and adapt configurations to your environment.*