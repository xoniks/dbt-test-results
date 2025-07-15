# Changelog

## [0.0.1] - 2025-07-15

### Added
- Initial release of dbt-test-results package
- Automatic capture and storage of dbt test results for configured models
- Support for `store_test_results` configuration in model schema.yml files
- On-run-end hook integration for seamless test result capture
- Delta Lake table creation with 7-column schema
- Configurable schema targeting via `absolute_schema` variable
- Support for all test types (not_null, unique, relationships, custom tests)
- Minimal logging and error handling

### Planned Features
- Source test result capture
- Optional bulk results table for all models
- Enhanced metadata and performance metrics