-- Custom test macros for integration testing

{% test email_format(model, column_name) %}
  -- Test that email addresses have a basic valid format
  SELECT *
  FROM {{ model }}
  WHERE {{ column_name }} IS NOT NULL
    AND {{ column_name }} NOT RLIKE '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
{% endtest %}

{% test positive_number(model, column_name) %}
  -- Test that a number column contains only positive values
  SELECT *
  FROM {{ model }}
  WHERE {{ column_name }} IS NOT NULL
    AND {{ column_name }} <= 0
{% endtest %}

{% test reasonable_price(model, column_name, max_price=10000) %}
  -- Test that prices are within a reasonable range
  SELECT *
  FROM {{ model }}
  WHERE {{ column_name }} IS NOT NULL
    AND {{ column_name }} > {{ max_price }}
{% endtest %}

{% test no_future_dates(model, column_name) %}
  -- Test that dates are not in the future
  SELECT *
  FROM {{ model }}
  WHERE {{ column_name }} IS NOT NULL
    AND DATE({{ column_name }}) > CURRENT_DATE()
{% endtest %}

{% test string_length_limit(model, column_name, max_length=255) %}
  -- Test that string fields don't exceed maximum length
  SELECT *
  FROM {{ model }}
  WHERE {{ column_name }} IS NOT NULL
    AND LENGTH({{ column_name }}) > {{ max_length }}
{% endtest %}

{% test inventory_consistency(model) %}
  -- Custom test to check inventory business rules
  SELECT *
  FROM {{ model }}
  WHERE (quantity < 0)  -- Negative inventory
    OR (reorder_level < 0)  -- Negative reorder level
    OR (quantity < reorder_level AND quantity > 0)  -- Low stock warning
{% endtest %}