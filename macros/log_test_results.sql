{% macro find_model_for_test(test_node, models_to_store) %}
  {% for dep_node in test_node.depends_on.nodes %}
    {% if dep_node.startswith('model.') %}
      {% set potential_model = dep_node.split('.')[-1] %}
      {% if potential_model in models_to_store %}
        {{ return(potential_model) }}
      {% endif %}
    {% endif %}
  {% endfor %}
  {{ return(none) }}
{% endmacro %}

{% macro store_test_results() %}
  {% if not results %}
    {{ return('') }}
  {% endif %}

  {% set test_results = results | selectattr('node.resource_type', 'equalto', 'test') | list %}
  {% if test_results | length == 0 %}
    {{ return('') }}
  {% endif %}

  {% set target_schema = var('dbt_test_results', {}).get('absolute_schema', 'test_results') %}
  {% set models_to_store = {} %}

  {# Find models with store_test_results config #}
  {% for node in graph.nodes.values() %}
    {% if node.resource_type == 'model' and node.config.get('store_test_results') %}
      {% set table_name = node.config.store_test_results %}
      {% set model_name = node.name %}
      {% do models_to_store.update({model_name: table_name}) %}
    {% endif %}
  {% endfor %}

  {% if models_to_store | length == 0 %}
    {{ return('') }}
  {% endif %}

  {% do log("dbt-test-results: Storing results for " ~ models_to_store | length ~ " configured models", info=true) %}

  {# Create schema if it doesn't exist #}
  {% if execute %}
    {% do run_query("CREATE SCHEMA IF NOT EXISTS " ~ target_schema) %}
  {% endif %}
  
  {# Create all tables first #}
  {% for model_name, table_name in models_to_store.items() %}
    {% set full_table_name = target_schema ~ '.' ~ table_name %}
    
    {% set create_table_sql %}
      CREATE TABLE IF NOT EXISTS {{ full_table_name }} (
        execution_id STRING,
        execution_timestamp TIMESTAMP,
        model_name STRING,
        test_name STRING,
        status STRING,
        failures BIGINT,
        test_unique_id STRING
      ) USING DELTA
    {% endset %}
    
    {% if execute %}
      {% do run_query(create_table_sql) %}
    {% endif %}
  {% endfor %}

  {# Process each test result #}
  {% for result in test_results %}
    {% set found_model = find_model_for_test(result.node, models_to_store) %}
    
    {% if found_model %}
      {% set table_name = models_to_store[found_model] %}
      {% set full_table_name = target_schema ~ '.' ~ table_name %}
      
      {% set insert_sql %}
        INSERT INTO {{ full_table_name }} VALUES (
          '{{ run_started_at.strftime('%Y%m%d_%H%M%S') }}',
          '{{ run_started_at }}',
          '{{ found_model }}',
          '{{ result.node.name }}',
          '{{ result.status }}',
          {{ result.failures or 0 }},
          '{{ result.node.unique_id }}'
        )
      {% endset %}
      
      {% if execute %}
        {% do run_query(insert_sql) %}
      {% endif %}
    {% endif %}
  {% endfor %}

  {{ return('') }}
{% endmacro %}


