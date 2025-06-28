-- Inventory data model for multi-model performance testing

{{ config(
    materialized='table'
) }}

WITH inventory_base AS (
  SELECT 
    ROW_NUMBER() OVER (ORDER BY RAND()) AS product_id,
    CONCAT('Product_', LPAD(CAST(ROW_NUMBER() OVER (ORDER BY RAND()) AS STRING), 6, '0')) AS product_name,
    FLOOR(RAND() * 1000) AS quantity_on_hand,
    ROUND(RAND() * 500, 2) AS unit_cost,
    CASE 
      WHEN RAND() > 0.8 THEN 'discontinued'
      WHEN RAND() > 0.1 THEN 'active'
      ELSE 'pending'
    END AS product_status
  FROM RANGE(2000)  -- Generate 2k products
)

SELECT * FROM inventory_base