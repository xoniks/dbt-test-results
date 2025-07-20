{% macro apply_databricks_column_tags() %}
  {% if not execute %}
    {{ return('') }}
  {% endif %}

  {% set models_with_tagging = {} %}
  
  {# Find models with store_test_results_tags enabled #}
  {% for node in graph.nodes.values() %}
    {% if node.resource_type == 'model' and node.config.get('store_test_results_tags', false) %}
      {% do models_with_tagging.update({node.name: node}) %}
    {% endif %}
  {% endfor %}

  {% if models_with_tagging | length == 0 %}
    {{ return('') }}
  {% endif %}

  {% do log("dbt-test-results: Applying Databricks column tags for " ~ models_with_tagging | length ~ " models", info=true) %}

  {# Process each model with tagging enabled #}
  {% for model_name, model_node in models_with_tagging.items() %}
    {% set column_tests = get_column_tests_for_model(model_node) %}
    
    {% if column_tests | length > 0 %}
      {% set model_relation = adapter.get_relation(database=model_node.database, schema=model_node.schema, identifier=model_node.alias or model_node.name) %}
      
      {% if model_relation %}
        {% for column_name, test_list in column_tests.items() %}
          {% set test_names = test_list | join(',') %}
          {% set tag_sql %}
            ALTER TABLE {{ model_relation }} 
            ALTER COLUMN {{ column_name }} SET TAGS ('dbt_tests' = '{{ test_names }}')
          {% endset %}
          
          {% do run_query(tag_sql) %}
        {% endfor %}
      {% endif %}
    {% endif %}
  {% endfor %}

  {{ return('') }}
{% endmacro %}

{% macro get_column_tests_for_model(model_node) %}
  {% set column_tests = {} %}
  
  {# Find all tests that depend on this model #}
  {% for test_node in graph.nodes.values() %}
    {% if test_node.resource_type == 'test' %}
      {# Check if this test depends on our model #}
      {% for dep_node in test_node.depends_on.nodes %}
        {% if dep_node == model_node.unique_id %}
          {# Extract column name and test type from test node #}
          {% set column_name = get_test_column_name(test_node) %}
          {% set test_type = get_test_type_name(test_node) %}
          
          {% if column_name and test_type %}
            {% if column_name not in column_tests %}
              {% do column_tests.update({column_name: []}) %}
            {% endif %}
            {% do column_tests[column_name].append(test_type) %}
          {% endif %}
        {% endif %}
      {% endfor %}
    {% endif %}
  {% endfor %}
  
  {{ return(column_tests) }}
{% endmacro %}

{% macro get_test_column_name(test_node) %}
  {% if test_node.test_metadata %}
    {% if test_node.test_metadata.kwargs %}
      {% if test_node.test_metadata.kwargs.column_name %}
        {{ return(test_node.test_metadata.kwargs.column_name) }}
      {% endif %}
    {% endif %}
  {% endif %}
  {{ return(none) }}
{% endmacro %}

{% macro get_test_type_name(test_node) %}
  {% if test_node.test_metadata %}
    {% if test_node.test_metadata.name %}
      {{ return(test_node.test_metadata.name) }}
    {% endif %}
  {% endif %}
  {{ return(none) }}
{% endmacro %}