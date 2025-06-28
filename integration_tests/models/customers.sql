-- Basic test model: customers table
-- Tests: unique, not_null, accepted_values
-- Results stored in: customers_test_log

{{ config(
    materialized='table'
) }}

SELECT
  row_number() OVER (ORDER BY 1) as customer_id,
  customer_data.*
FROM (
  VALUES
    ('john.doe@email.com', 'John', 'Doe', 'active', '2023-01-15'),
    ('jane.smith@email.com', 'Jane', 'Smith', 'active', '2023-02-20'),
    ('bob.johnson@email.com', 'Bob', 'Johnson', 'inactive', '2023-03-10'),
    ('alice.brown@email.com', 'Alice', 'Brown', 'pending', '2023-04-05'),
    ('charlie.wilson@email.com', 'Charlie', 'Wilson', 'active', '2023-05-12'),
    -- Intentional duplicate email for testing unique constraint failure
    ('duplicate@email.com', 'First', 'Duplicate', 'active', '2023-06-01'),
    ('duplicate@email.com', 'Second', 'Duplicate', 'active', '2023-06-02'),
    -- Null values for testing not_null constraint failure
    (NULL, 'Null', 'Email', 'active', '2023-07-01'),
    ('valid@email.com', NULL, 'LastName', 'active', '2023-07-02'),
    -- Invalid status for testing accepted_values failure
    ('invalid.status@email.com', 'Invalid', 'Status', 'suspended', '2023-08-01')
) AS customer_data(email, first_name, last_name, status, created_date)