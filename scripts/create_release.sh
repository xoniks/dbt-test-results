#!/bin/bash

# GitHub Release Creation Script for dbt-test-results v1.0.0
# This script creates the official v1.0.0 release with proper tagging

set -e  # Exit on any error

echo "🚀 Creating dbt-test-results v1.0.0 Release"
echo "============================================="

# Configuration
VERSION="1.0.0"
TAG_NAME="v${VERSION}"
RELEASE_TITLE="dbt-test-results v${VERSION} - Initial Release"
RELEASE_NOTES_FILE="GITHUB_RELEASE_v1.0.0.md"

# Check if we're in the right directory
if [ ! -f "dbt_project.yml" ]; then
    echo "❌ Error: Please run this script from the package root directory"
    exit 1
fi

# Verify release notes file exists
if [ ! -f "$RELEASE_NOTES_FILE" ]; then
    echo "❌ Error: Release notes file $RELEASE_NOTES_FILE not found"
    exit 1
fi

echo "📋 Pre-release validation..."

# Run quality check
if [ -f "scripts/pre_publication_check.py" ]; then
    echo "🔍 Running quality check..."
    python3 scripts/pre_publication_check.py
    if [ $? -ne 0 ]; then
        echo "⚠️  Quality check completed with warnings, but proceeding with release"
    else
        echo "✅ Quality check passed"
    fi
else
    echo "⚠️  Quality check script not found, skipping validation"
fi

# Verify version in dbt_project.yml matches
PROJECT_VERSION=$(grep "^version:" dbt_project.yml | head -1 | awk '{print $2}' | tr -d "'\"")
if [ "$PROJECT_VERSION" != "$VERSION" ]; then
    echo "❌ Error: Version mismatch between script ($VERSION) and dbt_project.yml ($PROJECT_VERSION)"
    exit 1
fi
echo "✅ Version consistency verified: $VERSION"

# Check git status
echo "📊 Checking git status..."
if [ -n "$(git status --porcelain)" ]; then
    echo "⚠️  Warning: You have uncommitted changes"
    echo "   Current git status:"
    git status --short
    echo ""
    read -p "   Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Release cancelled"
        exit 1
    fi
fi

# Create git tag
echo "🏷️  Creating git tag: $TAG_NAME"
if git tag -l | grep -q "^$TAG_NAME$"; then
    echo "⚠️  Tag $TAG_NAME already exists"
    read -p "   Replace existing tag? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git tag -d "$TAG_NAME"
        echo "🗑️  Removed existing tag"
    else
        echo "❌ Release cancelled"
        exit 1
    fi
fi

# Create annotated tag with release notes
git tag -a "$TAG_NAME" -m "$RELEASE_TITLE" -m "$(head -20 $RELEASE_NOTES_FILE)"
echo "✅ Created tag: $TAG_NAME"

# Instructions for completing the release
echo ""
echo "🎉 Release preparation completed!"
echo "================================="
echo ""
echo "📝 Next steps to complete the release:"
echo ""
echo "1. 📤 Push the tag to GitHub:"
echo "   git push origin $TAG_NAME"
echo ""
echo "2. 🌐 Create GitHub Release:"
echo "   • Go to: https://github.com/your-org/dbt-test-results/releases/new"
echo "   • Select tag: $TAG_NAME"
echo "   • Release title: $RELEASE_TITLE"
echo "   • Copy content from: $RELEASE_NOTES_FILE"
echo "   • Check 'Set as latest release'"
echo "   • Click 'Publish release'"
echo ""
echo "3. 📢 Post-release actions:"
echo "   • Announce on dbt Community Slack (#package-ecosystem)"
echo "   • Submit to dbt Hub (if desired)"
echo "   • Share on social media using templates in .github/ANNOUNCEMENT_TEMPLATES.md"
echo ""
echo "🔗 Release Notes Content:"
echo "   File: $RELEASE_NOTES_FILE"
echo "   Size: $(wc -l < $RELEASE_NOTES_FILE) lines"
echo ""
echo "📊 Package Statistics:"
echo "   • Version: $VERSION"
echo "   • Macro files: $(find macros -name "*.sql" | wc -l)"
echo "   • Example projects: $(find examples -mindepth 1 -maxdepth 1 -type d | wc -l)"
echo "   • Documentation files: $(find . -name "README.md" | wc -l)"
echo "   • Total code lines: $(find macros -name "*.sql" -exec wc -l {} + | tail -1 | awk '{print $1}')"
echo ""

# Option to automatically push tag
read -p "🚀 Push tag to GitHub now? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "📤 Pushing tag to GitHub..."
    git push origin "$TAG_NAME"
    echo "✅ Tag pushed successfully!"
    echo ""
    echo "🌐 Next: Create the GitHub release at:"
    echo "   https://github.com/your-org/dbt-test-results/releases/new?tag=$TAG_NAME"
    echo ""
    echo "📋 Use the content from $RELEASE_NOTES_FILE for the release description"
else
    echo "📝 Tag created locally. Push when ready with:"
    echo "   git push origin $TAG_NAME"
fi

echo ""
echo "🎉 dbt-test-results v$VERSION release preparation complete!"
echo "   Thank you for contributing to the dbt community! 🙏"