# Release Template for dbt-test-results

Use this template when creating a new release on GitHub.

## Release Title Format
```
dbt-test-results v[VERSION] - [RELEASE_TYPE]
```

Examples:
- `dbt-test-results v1.0.0 - Initial Release`
- `dbt-test-results v1.1.0 - Performance Improvements`
- `dbt-test-results v1.0.1 - Bug Fixes`

## Release Description Template

```markdown
## 🚀 What's New in v[VERSION]

[Brief summary of the release - 2-3 sentences describing the main highlights]

### ✨ New Features
- [Feature 1]: Description of new functionality
- [Feature 2]: Description of new functionality

### 🔧 Improvements
- [Improvement 1]: Description of enhancement
- [Improvement 2]: Description of enhancement

### 🐛 Bug Fixes
- Fixed: [Bug description and resolution]
- Fixed: [Bug description and resolution]

### ⚠️ Breaking Changes
- [Breaking change 1]: Description and migration guide
- [Breaking change 2]: Description and migration guide

### 📊 Performance
- [Performance improvement 1]: Quantified improvement
- [Performance improvement 2]: Quantified improvement

## 🔄 Migration Guide

### From v[PREVIOUS_VERSION] to v[VERSION]

1. **Configuration Changes**
   ```yaml
   # Old configuration
   vars:
     dbt_test_results:
       old_setting: value
   
   # New configuration
   vars:
     dbt_test_results:
       new_setting: value
   ```

2. **Required Actions**
   - [ ] Update packages.yml to new version
   - [ ] Run `dbt deps` to install dependencies
   - [ ] Update any custom configurations
   - [ ] Test in development environment

### Compatibility
- **dbt Core**: Requires >= 1.0.0
- **Adapters**: Spark/Databricks, BigQuery, Snowflake, PostgreSQL
- **Breaking Changes**: [Yes/No - list if any]

## 🏁 Quick Start

```bash
# 1. Add to packages.yml
packages:
  - git: https://github.com/your-org/dbt-test-results.git
    revision: v[VERSION]

# 2. Install package
dbt deps

# 3. Configure (minimal)
# dbt_project.yml
vars:
  dbt_test_results:
    enabled: true

# 4. Add to your models
# models/schema.yml
models:
  - name: your_model
    config:
      store_test_results: "your_test_results_table"
    tests:
      - unique:
          column_name: id

# 5. Run tests
dbt test
```

## 📈 Performance Benchmarks

| Scenario | Test Volume | Duration | Memory | Throughput |
|----------|-------------|----------|---------|------------|
| Small Project | 100 tests | 15s | 256MB | 6.7 tests/s |
| Medium Project | 1,000 tests | 45s | 512MB | 22.2 tests/s |
| Large Project | 10,000 tests | 180s | 2GB | 55.6 tests/s |

## 🔗 Links
- **📖 Documentation**: [Main README](../README.md)
- **🚀 Quick Start**: [examples/quickstart/](../examples/quickstart/)
- **⚙️ Advanced Guide**: [examples/advanced/](../examples/advanced/)
- **🏎️ Performance**: [examples/performance/](../examples/performance/)
- **🐛 Issues**: [GitHub Issues](https://github.com/your-org/dbt-test-results/issues)
- **💬 Discussions**: [GitHub Discussions](https://github.com/your-org/dbt-test-results/discussions)

## 🙏 Contributors
Special thanks to all contributors who made this release possible:
- [@contributor1](https://github.com/contributor1)
- [@contributor2](https://github.com/contributor2)

## 📋 Full Changelog
**Full Changelog**: https://github.com/your-org/dbt-test-results/compare/v[PREVIOUS_VERSION]...v[VERSION]

---

## 📥 Installation

### Option 1: Git Installation (Recommended)
```yaml
# packages.yml
packages:
  - git: https://github.com/your-org/dbt-test-results.git
    revision: v[VERSION]
  - package: dbt-labs/dbt_utils
    version: [">=0.8.0", "<2.0.0"]
```

### Option 2: dbt Hub (Once Published)
```yaml
# packages.yml  
packages:
  - package: your-org/dbt_test_results
    version: [">=1.0.0", "<2.0.0"]
```

### Verification
```bash
# Verify installation
dbt run-operation dbt_test_results.validate_configuration

# Test with sample data
dbt run --select examples
dbt test --select examples
```

## ⚠️ Known Issues
- [Known issue 1]: Description and workaround
- [Known issue 2]: Description and workaround

## 📅 Next Release
Expected features for v[NEXT_VERSION]:
- [Planned feature 1]
- [Planned feature 2]
- [Planned feature 3]

---

**Need help?** Check our [documentation](../README.md) or [open an issue](https://github.com/your-org/dbt-test-results/issues/new).
```

## 📝 Release Notes Guidelines

### Writing Style
- Use clear, concise language
- Focus on user impact, not implementation details
- Include actionable information for users
- Use consistent formatting and emoji for readability

### Version Numbering (Semantic Versioning)
- **MAJOR** (1.0.0 → 2.0.0): Breaking changes, incompatible API changes
- **MINOR** (1.0.0 → 1.1.0): New features, backwards-compatible
- **PATCH** (1.0.0 → 1.0.1): Bug fixes, backwards-compatible

### Required Sections
1. **What's New**: High-level summary
2. **Migration Guide**: For breaking changes
3. **Quick Start**: Copy-paste installation
4. **Performance**: Benchmarks when relevant
5. **Contributors**: Acknowledge community

### Optional Sections (use as needed)
- Breaking Changes (for major versions)
- Performance Improvements (with metrics)
- Known Issues
- Deprecation Notices
- Security Updates