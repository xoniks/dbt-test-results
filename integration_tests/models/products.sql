-- Products table for testing multiple models using same results table
-- Tests: unique, not_null
-- Results stored in: shared_test_results (same as inventory)

{{ config(
    materialized='table'
) }}

SELECT
  row_number() OVER (ORDER BY 1) as product_id,
  product_data.*
FROM (
  VALUES
    ('Laptop Pro 15"', 'Electronics', 1299.99, true),
    ('Wireless Mouse', 'Electronics', 29.99, true),
    ('Office Chair', 'Furniture', 199.99, true),
    ('Standing Desk', 'Furniture', 599.99, false),  -- Not available
    ('Coffee Mug', 'Kitchen', 12.99, true),
    -- Test cases for failures
    ('Duplicate Product', 'Test', 1.00, true),
    ('Duplicate Product', 'Test', 2.00, true),      -- Duplicate name
    (NULL, 'Test Category', 5.00, true),            -- NULL name
    ('Valid Product', NULL, 10.00, true),           -- NULL category
    ('Another Product', 'Test', NULL, true),        -- NULL price
    -- Edge cases
    ('Product with "Special" Characters & Symbols!', 'Special', 99.99, true),
    ('Very Long Product Name That Exceeds Normal Length Expectations For Product Names In Most Systems', 'Test', 1.99, true)
) AS product_data(name, category, price, available)