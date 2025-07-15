# Changelog

## [1.0.0] - 2025-07-15

### Added
- Initial release of dbt-test-results package
- Automatic capture and storage of dbt test results for configured models
- Support for `store_test_results` configuration in model schema.yml files
- On-run-end hook integration for seamless test result capture
- Delta Lake table creation with standard schema
- Configurable schema targeting via `absolute_schema` variable
- Support for all test types (not_null, unique, relationships, custom tests)