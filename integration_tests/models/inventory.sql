-- Inventory table sharing results table with products
-- Tests: not_null, unique, custom test
-- Results stored in: shared_test_results (same as products)

{{ config(
    materialized='table'
) }}

SELECT
  row_number() OVER (ORDER BY 1) as inventory_id,
  inventory_data.*
FROM (
  VALUES
    (1, 50, 10, '2023-01-01'),     -- product_id 1, 50 in stock, reorder at 10
    (2, 100, 25, '2023-01-01'),    -- product_id 2
    (3, 5, 20, '2023-01-01'),      -- Low stock (below reorder level)
    (4, 0, 15, '2023-01-01'),      -- Out of stock
    (5, 75, 30, '2023-01-01'),     -- product_id 5
    -- Test cases for failures
    (999, 25, 10, '2023-02-01'),   -- Duplicate inventory_id (will create duplicate in row_number)
    (999, 30, 15, '2023-02-02'),   -- Another duplicate
    (1, NULL, 10, '2023-03-01'),   -- NULL quantity
    (2, 50, NULL, '2023-03-01'),   -- NULL reorder_level
    (3, 25, 15, NULL),             -- NULL last_updated
    -- Edge cases
    (6, -5, 10, '2023-04-01'),     -- Negative quantity
    (7, 10000, 5000, '2023-04-01') -- Very high numbers
) AS inventory_data(product_id, quantity, reorder_level, last_updated)