# Pull Request

## 📋 Description

Brief description of the changes in this PR.

## 🔗 Related Issue

Fixes #(issue number) or Relates to #(issue number)

## 🎯 Type of Change

- [ ] 🐛 Bug fix (non-breaking change which fixes an issue)
- [ ] ✨ New feature (non-breaking change which adds functionality)
- [ ] 💥 Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] 📚 Documentation update
- [ ] 🔧 Configuration change
- [ ] 🧪 Test improvements
- [ ] ♻️ Code refactoring
- [ ] ⚡ Performance improvement

## 🧪 Testing

**Tests completed:**
- [ ] Integration tests pass (`./integration_tests/run_integration_tests.sh`)
- [ ] Package validation passes (`python .github/scripts/validate_package.py`)
- [ ] Security validation passes (`python .github/scripts/validate_security.py`)
- [ ] Added new tests for changes
- [ ] Tested with multiple dbt versions (if applicable)
- [ ] Manual testing completed

**Test scenarios covered:**
- [ ] Basic functionality
- [ ] Edge cases
- [ ] Error handling
- [ ] Different configurations
- [ ] Performance impact

**Testing details:**
```
Describe your testing approach and results
```

## 📸 Screenshots/Logs

If applicable, add screenshots or relevant log output.

```
Paste relevant logs here
```

## 🔄 Migration Guide

**For breaking changes only:**

**What breaks:**
- List what functionality changes or breaks

**Migration steps:**
1. Step 1
2. Step 2
3. Step 3

**Configuration changes required:**
```yaml
# Old configuration
old_config: value

# New configuration  
new_config: value
```

## 📚 Documentation

**Documentation updates:**
- [ ] Updated README.md
- [ ] Updated CHANGELOG.md
- [ ] Added/updated examples
- [ ] Added/updated macro documentation
- [ ] Updated configuration reference

**Documentation changes needed:**
- List any documentation that needs to be updated

## ✅ Checklist

**Code Quality:**
- [ ] Code follows project style guidelines
- [ ] Self-reviewed the code changes
- [ ] Added comments for complex logic
- [ ] Removed any debugging code
- [ ] No hardcoded values (use configuration)

**Testing:**
- [ ] Added tests for new functionality
- [ ] All existing tests pass
- [ ] Edge cases are covered
- [ ] Error scenarios are handled

**Documentation:**
- [ ] Added inline documentation for new macros
- [ ] Updated user-facing documentation
- [ ] Added examples if needed
- [ ] Updated CHANGELOG.md

**Security:**
- [ ] No hardcoded secrets or credentials
- [ ] Input validation for user-provided data
- [ ] SQL injection prevention measures
- [ ] Proper error handling

## 🚀 Deployment Notes

**Deployment considerations:**
- [ ] No deployment considerations
- [ ] Requires database schema changes
- [ ] Requires configuration updates
- [ ] Requires dbt version upgrade
- [ ] May impact performance

**Rollback plan:**
If this change needs to be rolled back, what steps are required?

## 📊 Performance Impact

**Performance considerations:**
- [ ] No performance impact
- [ ] Improves performance
- [ ] May impact performance (details below)
- [ ] Adds new configuration options for performance tuning

**Performance details:**
```
Describe any performance testing results or considerations
```

## 🤔 Questions for Reviewers

Any specific areas you'd like reviewers to focus on or questions you have about the implementation?

## 🎉 Additional Notes

Any additional information that would be helpful for reviewers.