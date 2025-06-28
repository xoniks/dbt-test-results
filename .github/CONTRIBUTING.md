# Contributing to dbt-test-results

Thank you for your interest in contributing to dbt-test-results! We welcome contributions from the community and appreciate your help in making this package better for everyone.

## 🌆 Quick Start

### Ways to Contribute
- 🐞 **Bug reports**: Help us identify and fix issues
- 💡 **Feature requests**: Suggest new capabilities
- 📝 **Documentation**: Improve guides and examples
- 🚀 **Code contributions**: Submit bug fixes and enhancements
- 🧪 **Testing**: Help validate changes across different environments
- 💬 **Community support**: Answer questions and help other users

### Before You Start
1. **Read our [Code of Conduct](CODE_OF_CONDUCT.md)**
2. **Check existing [issues](https://github.com/your-org/dbt-test-results/issues) and [discussions](https://github.com/your-org/dbt-test-results/discussions)**
3. **Review the [roadmap](#roadmap) to understand project direction**

## 🚀 Quick Start for Contributors

1. **Fork the repository** and clone your fork
2. **Set up development environment** (see [Development Setup](#development-setup))
3. **Create a feature branch** from `main`
4. **Make your changes** with tests
5. **Run tests** to ensure everything works
6. **Submit a pull request**

## 📋 Development Setup

### Prerequisites

- Python 3.7+
- dbt-core >= 1.0.0
- Git
- A supported database (Databricks recommended, DuckDB for local testing)

### Local Development

```bash
# Clone your fork
git clone https://github.com/yourusername/dbt-test-results.git
cd dbt-test-results

# Install development dependencies
pip install dbt-core dbt-duckdb  # or your preferred adapter

# Set up integration tests
cd integration_tests
cp profiles.yml.template profiles.yml
# Edit profiles.yml with your database connection

# Run tests to verify setup
dbt deps
dbt run
dbt test
```

## 🧪 Testing Your Changes

### Required Tests

Before submitting a PR, ensure:

1. **Integration tests pass**:
   ```bash
   cd integration_tests
   ./run_integration_tests.sh
   ```

2. **Package validation passes**:
   ```bash
   python .github/scripts/validate_package.py
   ```

3. **Security checks pass**:
   ```bash
   python .github/scripts/validate_security.py
   ```

4. **Multiple dbt versions work** (if changing core functionality):
   ```bash
   # Test with different dbt versions
   pip install dbt-core==1.5.0
   cd integration_tests && dbt test
   ```

### Writing Tests

- **New features**: Add corresponding test cases in `integration_tests/`
- **Bug fixes**: Include a test that reproduces the bug
- **Configuration changes**: Test different configuration scenarios
- **Performance improvements**: Include before/after benchmarks

## 📝 Pull Request Process

### Before You Submit

1. **Create an issue** first for new features or significant changes
2. **Update documentation** for any user-facing changes
3. **Add tests** for new functionality
4. **Update CHANGELOG.md** with your changes
5. **Ensure CI passes** - all tests must pass

### PR Requirements

- **Clear title** describing the change
- **Detailed description** explaining what and why
- **Link to related issue** if applicable
- **Breaking change notes** if applicable
- **Test results** showing your changes work

### PR Template

When creating a PR, please include:

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Testing
- [ ] Integration tests pass
- [ ] Added new tests for changes
- [ ] Tested with multiple dbt versions (if applicable)
- [ ] Manual testing completed

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-reviewed the code
- [ ] Added inline documentation for new macros
- [ ] Updated CHANGELOG.md
- [ ] Updated documentation if needed
```

## 🐛 Bug Reports

Great bug reports tend to have:

- **Clear title** that summarizes the issue
- **Environment details** (dbt version, database, OS)
- **Steps to reproduce** the behavior
- **Expected vs actual behavior**
- **Minimal example** that demonstrates the issue
- **Error messages** and logs
- **Screenshots** if helpful

Use the [bug report template](.github/ISSUE_TEMPLATE/bug_report.md) when filing issues.

## 💡 Feature Requests

Feature requests should include:

- **Problem description** - what problem does this solve?
- **Proposed solution** - how should it work?
- **Alternatives considered** - what other approaches did you consider?
- **Use case** - when would this be useful?
- **Implementation ideas** - any thoughts on how to implement?

Use the [feature request template](.github/ISSUE_TEMPLATE/feature_request.md) for new features.

## 📚 Documentation

Documentation improvements are always welcome! This includes:

- **README.md** improvements
- **Inline macro documentation** 
- **Example enhancements**
- **Configuration guides**
- **Troubleshooting guides**
- **Best practices**

### Documentation Standards

- Use clear, concise language
- Include code examples where helpful
- Keep examples up-to-date with current syntax
- Cross-reference related sections
- Include troubleshooting tips

## 🎨 Code Style

### SQL Style

- **Lowercase keywords**: `select`, `from`, `where`
- **Snake_case identifiers**: `table_name`, `column_name`
- **Consistent indentation**: 2 spaces
- **Comments**: Use `{# #}` for documentation blocks
- **Line length**: Aim for 80 characters, max 120

### Macro Documentation

All macros must include documentation:

```sql
{#
  Brief description of what the macro does.
  
  Args:
    param1: Description of parameter
    param2: Description of parameter
  
  Returns:
    Description of return value
  
  Usage:
    {% set result = macro_name(arg1, arg2) %}
#}
{% macro macro_name(param1, param2) %}
```

### Configuration

- **Validate inputs** where possible
- **Provide defaults** for optional parameters
- **Use descriptive variable names**
- **Include helpful error messages**

## 🔄 Release Process

### Versioning

We follow [Semantic Versioning](https://semver.org/):

- **MAJOR**: Incompatible API changes
- **MINOR**: Backwards-compatible functionality additions
- **PATCH**: Backwards-compatible bug fixes

### Release Checklist

1. Update version in `dbt_project.yml`
2. Update `CHANGELOG.md` with release notes
3. Create GitHub release with tag
4. Verify CI passes for release
5. Update documentation if needed

## 🤝 Community Guidelines

### Code of Conduct

- **Be respectful** and inclusive
- **Be constructive** in feedback
- **Help others** learn and grow
- **Assume good intentions**
- **Focus on the code**, not the person

### Getting Help

- **Search existing issues** before creating new ones
- **Use GitHub Discussions** for questions
- **Provide context** when asking for help
- **Share solutions** that work for you

### Recognition

Contributors will be:
- **Listed in CHANGELOG.md** for their contributions
- **Mentioned in release notes** for significant features
- **Added to contributors list** in README.md

## 🛠️ Development Tips

### Local Testing

```bash
# Quick syntax check
dbt parse

# Test specific models
dbt run --models my_model
dbt test --models my_model

# Debug macro execution
dbt run-operation my_macro --args '{arg1: "value"}'

# Enable debug logging
dbt test --vars '{dbt_test_results: {debug_mode: true}}'
```

### Performance Testing

```bash
# Test with different batch sizes
dbt test --vars '{dbt_test_results: {batch_size: 100}}'
dbt test --vars '{dbt_test_results: {batch_size: 5000}}'

# Test with large datasets
# Add more test data to integration_tests/models/
```

### Debugging Issues

1. **Enable debug mode**: `debug_mode: true`
2. **Check logs**: Look for "dbt-test-results" messages
3. **Validate configuration**: Use `validate_configuration()` macro
4. **Test incrementally**: Start with one model
5. **Check database directly**: Query result tables manually

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/xoniks/dbt-test-results/issues)
- **Discussions**: [GitHub Discussions](https://github.com/xoniks/dbt-test-results/discussions)
- **Documentation**: [README.md](../README.md) and [examples/](../examples/)

## 🙏 Acknowledgments

Thank you to all contributors who help make this project better! Special thanks to:

- The dbt community for inspiration and feedback
- dbt Labs for the excellent dbt framework
- All users who report bugs and suggest improvements

---

**Happy Contributing!** 🎉