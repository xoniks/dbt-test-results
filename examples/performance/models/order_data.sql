-- Order data model for multi-model performance testing

{{ config(
    materialized='table'
) }}

WITH order_base AS (
  SELECT 
    ROW_NUMBER() OVER (ORDER BY RAND()) AS order_id,
    FLOOR(RAND() * 10000) + 1 AS customer_id,  -- Reference to large_dataset
    ROUND(RAND() * 1000, 2) AS order_amount,
    DATE_ADD('2023-01-01', CAST(RAND() * 365 AS INT)) AS order_date,
    CASE 
      WHEN RAND() > 0.9 THEN 'cancelled'
      WHEN RAND() > 0.8 THEN 'pending' 
      ELSE 'completed'
    END AS order_status
  FROM RANGE(5000)  -- Generate 5k orders
)

SELECT * FROM order_base