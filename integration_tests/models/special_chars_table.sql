-- Table with special characters in name and content
-- Tests edge cases for table/column name handling
-- Results stored in: special_chars_test_results

{{ config(
    materialized='table'
) }}

SELECT
  row_number() OVER (ORDER BY 1) as id,
  test_data.*
FROM (
  VALUES
    ('O''Brien', 'Test with single quote'),
    ('Smith & Jones', 'Test with ampersand'),
    ('Data with "quotes"', 'Test with double quotes'),
    ('Line 1\nLine 2', 'Test with newline'),
    ('Tab\tSeparated', 'Test with tab'),
    ('Unicode: café, naïve, résumé', 'Test with unicode'),
    ('SQL Injection; DROP TABLE--', 'Test SQL injection attempt'),
    ('Very long text that might exceed normal field lengths and could potentially cause issues with storage or processing in some database systems', 'Long text test'),
    (NULL, 'NULL name test'),
    ('Valid Name', NULL),  -- NULL description
    ('', 'Empty string name'),  -- Empty string
    ('   ', 'Whitespace only name')  -- Whitespace only
) AS test_data(name_with_special_chars, description)