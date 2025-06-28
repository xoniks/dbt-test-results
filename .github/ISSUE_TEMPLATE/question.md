---
name: Question or Help
about: Ask a question or get help with usage
title: '[QUESTION] '
labels: 'question'
assignees: ''

---

## ❓ Question

Clearly state your question here.

## 🎯 What are you trying to achieve?

Describe what you're trying to accomplish with dbt-test-results.

## 🔧 Current Setup

**Your configuration:**
```yaml
# dbt_project.yml
vars:
  dbt_test_results:
    # Your current configuration
```

```yaml
# schema.yml 
models:
  - name: your_model
    config:
      store_test_results: "table_name"
    # Your current setup
```

## 🖥️ Environment

**dbt version:** ___
**Database:** ___
**Package version:** ___

## 🔍 What have you tried?

Describe what you've already attempted:

- [ ] Reviewed the [README](../../README.md)
- [ ] Checked the [examples](../../examples/)
- [ ] Looked at [integration tests](../../integration_tests/)
- [ ] Searched existing issues
- [ ] Enabled debug mode
- [ ] Tried different configurations

## 📋 Additional Context

Add any other context, error messages, or relevant information here.

## 💡 Specific Help Needed

What specific help or guidance are you looking for?

---

**Note:** For bug reports, please use the [bug report template](bug_report.md) instead.