-- Orders table with relationships test
-- Tests: unique, not_null, relationships
-- Results stored in: orders_test_results

{{ config(
    materialized='table'
) }}

SELECT
  row_number() OVER (ORDER BY 1) as order_id,
  order_data.*
FROM (
  VALUES
    (1, 100.50, '2023-01-20', 'completed'),
    (2, 250.75, '2023-02-25', 'completed'),
    (3, 75.25, '2023-03-15', 'pending'),
    (1, 150.00, '2023-04-10', 'completed'),  -- Valid: same customer, different order
    (4, 300.25, '2023-05-18', 'completed'),
    -- Intentional duplicate order_id for testing
    (999, 50.00, '2023-06-01', 'completed'),
    (999, 75.00, '2023-06-02', 'completed'),  -- Duplicate order_id
    -- NULL values for testing
    (2, NULL, '2023-07-01', 'completed'),     -- NULL amount
    (3, 125.50, NULL, 'completed'),           -- NULL order_date
    (1, 200.00, '2023-08-01', NULL),          -- NULL status
    -- Invalid customer_id (no relationship)
    (999, 99.99, '2023-09-01', 'completed'),  -- customer_id 999 doesn't exist
    -- Edge case: very large amount
    (5, 999999.99, '2023-10-01', 'completed')
) AS order_data(customer_id, amount, order_date, status)