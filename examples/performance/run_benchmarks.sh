#!/bin/bash

# Performance benchmarking script for dbt-test-results package
# This script runs comprehensive performance tests and generates reports

set -e  # Exit on any error

echo "=========================================="
echo "dbt-test-results Performance Benchmarks"
echo "=========================================="

# Check if we're in the right directory
if [ ! -f "dbt_project.yml" ]; then
    echo "Error: Please run this script from the performance examples directory"
    exit 1
fi

# Configuration
BENCHMARK_RUNS=3
RESULTS_FILE="benchmark_results_$(date +%Y%m%d_%H%M%S).log"
CSV_RESULTS="benchmark_results_$(date +%Y%m%d_%H%M%S).csv"

echo "Results will be saved to: $RESULTS_FILE"
echo "CSV results will be saved to: $CSV_RESULTS"
echo ""

# Initialize CSV file
echo "run_number,scenario,operation,duration_seconds,records_processed,throughput_per_second,memory_estimate_mb,batch_size,success" > "$CSV_RESULTS"

# Function to run a benchmark scenario
run_benchmark() {
    local scenario_name="$1"
    local batch_size="$2"
    local additional_vars="$3"
    
    echo "Running benchmark: $scenario_name (batch_size: $batch_size)"
    
    # Clean previous run
    dbt clean > /dev/null 2>&1 || true
    
    # Start timing
    start_time=$(date +%s.%N)
    
    # Run the benchmark
    if dbt run --vars "{dbt_test_results: {batch_size: $batch_size, $additional_vars}}" > temp_run.log 2>&1; then
        run_success="true"
        echo "  ✅ dbt run completed successfully"
    else
        run_success="false"
        echo "  ❌ dbt run failed"
        cat temp_run.log
    fi
    
    # Run tests (this triggers test result storage)
    if dbt test --vars "{dbt_test_results: {batch_size: $batch_size, $additional_vars}}" > temp_test.log 2>&1; then
        test_success="true"
        echo "  ✅ dbt test completed successfully"
    else
        test_success="false"
        echo "  ⚠️  dbt test had failures (expected for benchmarking)"
    fi
    
    # End timing
    end_time=$(date +%s.%N)
    duration=$(echo "$end_time - $start_time" | bc)
    
    # Extract metrics from logs
    test_count=$(grep -o "PASS\|FAIL\|ERROR" temp_test.log | wc -l || echo "0")
    throughput=$(echo "scale=2; $test_count / $duration" | bc || echo "0")
    memory_estimate=$(echo "scale=2; $test_count * 1024 / 1024 / 1024" | bc || echo "0")
    
    echo "  📊 Duration: ${duration}s, Tests: $test_count, Throughput: ${throughput}/s"
    
    # Log to files
    echo "[$scenario_name] Duration: ${duration}s, Tests: $test_count, Batch Size: $batch_size" >> "$RESULTS_FILE"
    echo "$run_number,$scenario_name,complete,$duration,$test_count,$throughput,$memory_estimate,$batch_size,$test_success" >> "$CSV_RESULTS"
    
    # Cleanup
    rm -f temp_run.log temp_test.log
    
    echo ""
}

# Function to analyze results
analyze_results() {
    echo "=========================================="
    echo "Performance Analysis"
    echo "=========================================="
    
    if [ -f "$CSV_RESULTS" ]; then
        echo "📈 Performance Summary:"
        echo ""
        
        # Best throughput
        best_throughput=$(tail -n +2 "$CSV_RESULTS" | cut -d',' -f6 | sort -nr | head -1)
        best_scenario=$(tail -n +2 "$CSV_RESULTS" | sort -t',' -k6 -nr | head -1 | cut -d',' -f2)
        echo "  🏆 Best Throughput: $best_throughput tests/second ($best_scenario)"
        
        # Average duration by batch size
        echo ""
        echo "  📊 Average Duration by Batch Size:"
        for batch_size in 100 1000 5000 10000; do
            avg_duration=$(tail -n +2 "$CSV_RESULTS" | awk -F',' -v bs="$batch_size" '$8==bs {sum+=$4; count++} END {if(count>0) printf "%.2f", sum/count; else print "N/A"}')
            if [ "$avg_duration" != "N/A" ]; then
                echo "    Batch Size $batch_size: ${avg_duration}s"
            fi
        done
        
        # Memory usage analysis
        echo ""
        echo "  💾 Memory Usage Estimates:"
        max_memory=$(tail -n +2 "$CSV_RESULTS" | cut -d',' -f7 | sort -nr | head -1)
        echo "    Peak Memory: ${max_memory}MB"
        
        # Success rate
        success_count=$(tail -n +2 "$CSV_RESULTS" | cut -d',' -f9 | grep -c "true" || echo "0")
        total_runs=$(tail -n +2 "$CSV_RESULTS" | wc -l)
        success_rate=$(echo "scale=1; $success_count * 100 / $total_runs" | bc || echo "0")
        echo "    Success Rate: ${success_rate}%"
        
    fi
    
    echo ""
    echo "📋 Detailed results saved to: $RESULTS_FILE"
    echo "📊 CSV data saved to: $CSV_RESULTS"
}

# Function to generate performance recommendations
generate_recommendations() {
    echo "=========================================="
    echo "Performance Recommendations"
    echo "=========================================="
    
    # Analyze adapter type
    adapter_type=$(dbt debug 2>/dev/null | grep "adapter type" | awk '{print $3}' || echo "unknown")
    echo "🔧 Detected adapter: $adapter_type"
    
    case $adapter_type in
        "spark"|"databricks")
            echo ""
            echo "📋 Databricks/Spark Recommendations:"
            echo "  • Use batch_size between 5000-25000 for optimal performance"
            echo "  • Enable use_merge_strategy: true for better concurrency"
            echo "  • Set enable_parallel_processing: true for large datasets"
            echo "  • Consider delta.autoOptimize.optimizeWrite: true"
            ;;
        "bigquery")
            echo ""
            echo "📋 BigQuery Recommendations:"
            echo "  • Use batch_size between 10000-50000 for optimal performance"
            echo "  • Enable clustering on (model_name, test_type, status)"
            echo "  • Consider partitioning by DATE(execution_timestamp)"
            echo "  • Use streaming inserts for real-time processing"
            ;;
        "snowflake")
            echo ""
            echo "📋 Snowflake Recommendations:"
            echo "  • Use batch_size between 5000-25000 for optimal performance"
            echo "  • Enable clustering on (execution_timestamp, model_name)"
            echo "  • Consider using VARIANT data type for metadata"
            echo "  • Optimize warehouse size based on test volume"
            ;;
        *)
            echo ""
            echo "📋 General Recommendations:"
            echo "  • Start with batch_size: 1000 and increase based on performance"
            echo "  • Monitor memory usage and adjust batch sizes accordingly"
            echo "  • Enable debug_mode: true for troubleshooting"
            echo "  • Consider table partitioning for large result sets"
            ;;
    esac
    
    echo ""
    echo "💡 General Performance Tips:"
    echo "  • Run benchmarks during off-peak hours for consistent results"
    echo "  • Monitor database query performance during test execution"
    echo "  • Consider result table maintenance and cleanup policies"
    echo "  • Use selective test execution for large projects"
}

# Main benchmark execution
echo "🚀 Starting performance benchmarks..."
echo "Date: $(date)"
echo "dbt version: $(dbt --version | head -1)"
echo ""

# Install dependencies
echo "📦 Installing dependencies..."
dbt deps > /dev/null 2>&1

# Verify database connection
echo "🔗 Verifying database connection..."
if ! dbt debug > debug.log 2>&1; then
    echo "❌ Database connection failed. Check debug.log for details."
    exit 1
fi
echo "✅ Database connection verified"
echo ""

# Run benchmarks with different configurations
for run_number in $(seq 1 $BENCHMARK_RUNS); do
    echo "=========================================="
    echo "Benchmark Run $run_number of $BENCHMARK_RUNS"
    echo "=========================================="
    
    # Scenario 1: Small batch size
    run_benchmark "small_batch" 100 "enable_parallel_processing: false"
    
    # Scenario 2: Medium batch size
    run_benchmark "medium_batch" 1000 "enable_parallel_processing: false"
    
    # Scenario 3: Large batch size
    run_benchmark "large_batch" 5000 "enable_parallel_processing: true"
    
    # Scenario 4: Extra large batch size (if supported)
    run_benchmark "xlarge_batch" 10000 "enable_parallel_processing: true, use_merge_strategy: true"
    
    echo "Completed run $run_number of $BENCHMARK_RUNS"
    echo ""
done

# Analysis and recommendations
analyze_results
generate_recommendations

echo ""
echo "🎉 Performance benchmarking completed!"
echo ""
echo "Next steps:"
echo "1. Review the results in $RESULTS_FILE"
echo "2. Import $CSV_RESULTS into your preferred analysis tool"
echo "3. Apply the recommended configuration changes"
echo "4. Monitor production performance after deployment"