-- Simple customers model for quickstart example
-- This model demonstrates basic dbt-test-results usage

{{ config(
    materialized='table'
) }}

SELECT
  1 as customer_id,
  'john.doe@example.com' as email,
  'John' as first_name,
  'Doe' as last_name,
  'active' as status,
  '2023-01-01' as created_at

UNION ALL

SELECT
  2 as customer_id,
  'jane.smith@example.com' as email,
  'Jane' as first_name,
  'Smith' as last_name,
  'active' as status,
  '2023-01-02' as created_at

UNION ALL

SELECT
  3 as customer_id,
  'bob.wilson@example.com' as email,
  'Bob' as first_name,
  'Wilson' as last_name,
  'inactive' as status,
  '2023-01-03' as created_at