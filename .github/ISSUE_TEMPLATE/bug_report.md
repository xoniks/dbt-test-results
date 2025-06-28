---
name: Bug report
about: Create a report to help us improve
title: '[BUG] '
labels: 'bug'
assignees: ''

---

## 🐛 Bug Description

A clear and concise description of what the bug is.

## 🔄 Steps to Reproduce

Steps to reproduce the behavior:
1. Go to '...'
2. Click on '....'
3. Scroll down to '....'
4. See error

## ✅ Expected Behavior

A clear and concise description of what you expected to happen.

## ❌ Actual Behavior

A clear and concise description of what actually happened.

## 📸 Screenshots/Logs

If applicable, add screenshots or error logs to help explain your problem.

```
Paste error logs here
```

## 🖥️ Environment

**dbt version:**
- [ ] 1.0.x
- [ ] 1.1.x
- [ ] 1.2.x
- [ ] 1.3.x
- [ ] 1.4.x
- [ ] 1.5.x
- [ ] 1.6.x
- [ ] 1.7.x
- [ ] Other: ___

**Database:**
- [ ] Databricks
- [ ] Spark
- [ ] BigQuery
- [ ] Snowflake
- [ ] PostgreSQL
- [ ] Other: ___

**Operating System:**
- [ ] Windows
- [ ] macOS
- [ ] Linux
- [ ] Other: ___

**Package version:**
- [ ] Latest from main branch
- [ ] Specific version: ___

## ⚙️ Configuration

Please share relevant parts of your configuration:

**dbt_project.yml** (dbt-test-results section):
```yaml
vars:
  dbt_test_results:
    # Your configuration here
```

**schema.yml** (relevant model):
```yaml
models:
  - name: your_model
    config:
      store_test_results: "table_name"
    # Your configuration here
```

## 🔬 Minimal Reproduction

If possible, provide a minimal example that reproduces the issue:

**Model SQL:**
```sql
-- Your model SQL here
```

**Test configuration:**
```yaml
# Your test configuration here
```

## 📋 Additional Context

Add any other context about the problem here.

- [ ] This is a regression (it worked before)
- [ ] This only happens with specific configurations
- [ ] This only happens with large datasets
- [ ] This is blocking production usage

## 🔍 Investigation

Have you tried any of these steps?

- [ ] Enabled debug mode (`debug_mode: true`)
- [ ] Checked dbt logs for errors
- [ ] Verified database permissions
- [ ] Tested with a simpler configuration
- [ ] Checked if test result tables are created
- [ ] Reviewed [troubleshooting guide](../../README.md#troubleshooting)

## 💡 Proposed Solution

If you have ideas on how to fix this issue, please share them here.