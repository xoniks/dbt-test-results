# Complete dbt Hub Submission Process

## 📋 Pre-Submission Checklist

### **1. Repository Setup** ✅
- [x] Package hosted on GitHub with public access
- [x] Repository contains valid `dbt_project.yml` 
- [x] MIT license file present
- [x] Comprehensive README with usage instructions
- [x] Semantic versioning tag (v1.0.0) created
- [x] No hardcoded table references (uses `ref()` and `source()`)

### **2. Package Quality** ✅
- [x] Cross-database compatibility via dbt dispatch pattern
- [x] Proper resource naming (prefixed with `dbt_test_results`)
- [x] Configuration via variables
- [x] Dependencies properly managed
- [x] Security validated (no SQL injection, secrets)

### **3. Documentation** ✅
- [x] Compatible data warehouses documented
- [x] Installation instructions clear
- [x] Configuration options explained
- [x] Usage examples provided
- [x] dbt-core version compatibility specified (>=1.0.0)

---

## 🚀 Step-by-Step Submission Process

### **Step 1: Determine Your GitHub Information**

1. **Find your GitHub username from your repository URL:**
   ```
   https://github.com/[YOUR_USERNAME]/dbt-test-results
   ```

2. **Validate your username format:**
   ```bash
   python3 dbt_hub_submission/validate_hub_entry.py [YOUR_USERNAME]
   ```

### **Step 2: Update Repository URLs**

Update `dbt_project.yml` with your actual GitHub information:

```yaml
# Replace placeholder URLs with actual repository
repository: "https://github.com/[YOUR_USERNAME]/dbt-test-results"
homepage: "https://github.com/[YOUR_USERNAME]/dbt-test-results"
documentation: "https://github.com/[YOUR_USERNAME]/dbt-test-results#readme"
bug_tracker: "https://github.com/[YOUR_USERNAME]/dbt-test-results/issues"
```

### **Step 3: Fork the Hubcap Repository**

1. **Navigate to hubcap repository:**
   https://github.com/dbt-labs/hubcap

2. **Click "Fork" button** (top right)

3. **Clone your fork locally:**
   ```bash
   git clone https://github.com/[YOUR_USERNAME]/hubcap.git
   cd hubcap
   ```

### **Step 4: Edit hub.json**

1. **Open `hub.json` in your editor**

2. **Find the correct alphabetical position** for your username

3. **Add your entry** maintaining alphabetical order:

   **If you're a new organization:**
   ```json
   {
       "existing-org-before": [...],
       "[YOUR_USERNAME]": [
           "dbt-test-results"
       ],
       "existing-org-after": [...] 
   }
   ```

   **If your organization already exists:**
   ```json
   {
       "[YOUR_USERNAME]": [
           "existing-package-a",
           "dbt-test-results",
           "existing-package-z"
       ]
   }
   ```

### **Step 5: Validate Your Changes**

1. **Check JSON syntax:**
   ```bash
   python3 -m json.tool hub.json > /dev/null && echo "✅ JSON is valid" || echo "❌ JSON is invalid"
   ```

2. **Validate hub entry format:**
   ```bash
   python3 /path/to/validate_hub_entry.py --file hub.json [YOUR_USERNAME]
   ```

3. **Verify alphabetical ordering:**
   - Check that your username is in the correct position
   - Check that packages within your organization are alphabetically ordered

### **Step 6: Commit and Push Changes**

```bash
# Add the changes
git add hub.json

# Commit with descriptive message
git commit -m "Add dbt-test-results package to dbt Hub"

# Push to your fork
git push origin main
```

### **Step 7: Create Pull Request**

1. **Navigate to your fork on GitHub**

2. **Click "Contribute" → "Open pull request"**

3. **Use the PR template from `PR_DESCRIPTION_TEMPLATE.md`**
   - Copy the PR description
   - Replace `[YOUR_GITHUB_USERNAME]` with your actual username
   - Verify all links are correct

4. **Submit the pull request**

---

## 📝 Hub.json Entry Examples

### **Example 1: New Individual Developer**
Username: `johndoe`
```json
{
    "Aaron-Zhou": ["dbt-profiler"],
    "johndoe": [
        "dbt-test-results"
    ],
    "dbt-labs": ["dbt-utils", "codegen"]
}
```

### **Example 2: New Organization**
Organization: `datacompany`
```json
{
    "calogica": ["dbt-expectations"],
    "datacompany": [
        "dbt-test-results"
    ],
    "dbt-labs": ["dbt-utils", "codegen"]
}
```

### **Example 3: Existing Organization Adding Package**
Organization: `montreal-analytics` (already has packages)
```json
{
    "montreal-analytics": [
        "dbt-ga4",
        "dbt-snowplow-web",
        "dbt-test-results"
    ]
}
```

---

## 🔍 JSON Validation Commands

### **Basic Syntax Check:**
```bash
python3 -m json.tool hub.json
```

### **Advanced Validation:**
```bash
# Using our custom validator
python3 dbt_hub_submission/validate_hub_entry.py your-username

# Validate existing file
python3 dbt_hub_submission/validate_hub_entry.py --file hub.json your-username
```

### **Common JSON Errors:**
```json
// ❌ Wrong: Trailing comma
{
    "username": [
        "package-name",  // Remove this comma
    ]
}

// ✅ Correct: No trailing comma
{
    "username": [
        "package-name"
    ]
}
```

---

## 📋 Complete PR Description Template

### **PR Title:**
```
Add dbt-test-results package to dbt Hub
```

### **PR Body:** 
*(Copy from `PR_DESCRIPTION_TEMPLATE.md` and customize)*

Key sections to customize:
- Replace `[YOUR_GITHUB_USERNAME]` with actual username
- Update repository URLs
- Verify performance claims
- Add your maintainer commitment

---

## ⚡ Quick Submission Script

### **Automated Helper Script:**
```bash
#!/bin/bash
# Quick submission helper

USERNAME=$1
if [ -z "$USERNAME" ]; then
    echo "Usage: ./quick_submit.sh your-github-username"
    exit 1
fi

echo "🚀 dbt Hub Quick Submission for: $USERNAME"

# Validate username format
python3 dbt_hub_submission/validate_hub_entry.py $USERNAME

# Generate sample entry
echo "📝 Your hub.json entry should be:"
echo "    \"$USERNAME\": ["
echo "        \"dbt-test-results\""
echo "    ]"

echo ""
echo "📋 Next steps:"
echo "1. Fork https://github.com/dbt-labs/hubcap"
echo "2. Edit hub.json to add your entry in alphabetical order"
echo "3. Create PR with title: 'Add dbt-test-results package to dbt Hub'"
echo "4. Use description from PR_DESCRIPTION_TEMPLATE.md"
```

---

## 🎯 Post-Submission Process

### **What Happens After Submission:**

1. **Initial Review (1-2 business days)**
   - dbt Labs team reviews PR for completeness
   - Automated checks verify JSON syntax
   - Manual review of package quality

2. **Approval & Merge**
   - If approved, PR is merged to main branch
   - Package appears in hub.json

3. **Automatic Processing**
   - hubcap.py runs hourly checking for new releases
   - When v1.0.0 is detected, automatic PR created to hub.getdbt.com
   - Package becomes available on dbt Hub website

### **Timeline Expectations:**
- **PR Review**: 1-2 business days
- **Hub Appearance**: Within 24 hours of approval
- **Automatic Updates**: Hourly checks for new versions

---

## 🚨 Common Issues & Solutions

### **JSON Syntax Errors**
```bash
# Validate before submitting
python3 -m json.tool hub.json
```

### **Alphabetical Ordering Issues**
- Organizations must be in alphabetical order (case-sensitive)
- Packages within organizations must be alphabetically ordered
- Use validation script to check positioning

### **Repository Access Issues**
- Ensure repository is public
- Verify `dbt_project.yml` contains `name:` field
- Check that v1.0.0 tag exists and is accessible

### **Package Name Conflicts**
- Ensure package name is unique on the Hub
- Search existing packages before submitting
- Consider prefixing with organization name if needed

---

## 📞 Support & Help

### **Before Submitting:**
- Review [package best practices](https://github.com/dbt-labs/hubcap/blob/main/package-best-practices.md)
- Use validation script to check entry format
- Test package installation from GitHub

### **During Review:**
- Monitor PR for comments from dbt Labs team
- Respond promptly to any feedback or requests
- Make necessary changes if issues are identified

### **After Approval:**
- Monitor package appearance on hub.getdbt.com
- Update documentation to reference Hub installation
- Announce package availability to community

### **Getting Help:**
- **dbt Community Slack**: #package-ecosystem channel
- **GitHub Issues**: Open issue in hubcap repository for technical problems
- **Package Issues**: Use your package repository for user support

---

## 🎉 Success Indicators

### **Submission Successful When:**
✅ PR merged to hubcap repository  
✅ Package appears in hub.json file  
✅ Package listed on hub.getdbt.com  
✅ Installation works via dbt Hub  
✅ Hourly updates detect new releases  

### **Ready for Community:**
🚀 Package available on dbt Hub  
📢 Community announcement ready  
🔄 Automatic version updates working  
📖 Documentation updated with Hub installation  
🤝 Support channels established  

---

**The dbt Hub submission process ensures high-quality packages reach the community while maintaining the Hub's reputation for reliable, well-maintained dbt packages.**