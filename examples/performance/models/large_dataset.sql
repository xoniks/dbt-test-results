-- Large dataset model for performance benchmarking
-- Generates significant volume of data to test package performance

{{ config(
    materialized='table'
) }}

WITH base_numbers AS (
  SELECT sequence(1, 10000) AS numbers
),

expanded_numbers AS (
  SELECT EXPLODE(numbers) AS id
  FROM base_numbers
),

customer_data AS (
  SELECT
    id AS customer_id,
    CONCAT('customer_', LPAD(CAST(id AS STRING), 8, '0'), '@example.com') AS email,
    CASE 
      WHEN id % 10000 = 0 THEN NULL  -- Some null emails for testing
      ELSE CONCAT('customer_', LPAD(CAST(id AS STRING), 8, '0'), '@example.com')
    END AS email_with_nulls,
    CONCAT('Customer ', id) AS customer_name,
    CASE 
      WHEN id % 3 = 0 THEN 'premium'
      WHEN id % 3 = 1 THEN 'standard' 
      ELSE 'basic'
    END AS tier,
    CASE 
      WHEN id % 100 = 0 THEN 'inactive'
      WHEN id % 50 = 0 THEN 'pending'
      ELSE 'active'
    END AS status,
    ROUND(RAND() * 10000, 2) AS lifetime_value,
    DATE_ADD('2020-01-01', CAST(RAND() * 1000 AS INT)) AS created_date,
    CASE 
      WHEN id % 1000 = 0 THEN id  -- Some duplicates for testing unique constraints
      ELSE id
    END AS potentially_duplicate_id,
    -- Add some edge cases
    CASE 
      WHEN id % 5000 = 0 THEN ''  -- Empty string
      WHEN id % 5001 = 0 THEN '   '  -- Whitespace
      WHEN id % 5002 = 0 THEN 'Test with "quotes" and special chars!'
      ELSE CONCAT('Customer ', id)
    END AS name_with_edge_cases
  FROM expanded_numbers
  WHERE id <= 10000  -- Limit to 10k records for reasonable performance
)

SELECT * FROM customer_data