#!/usr/bin/env python3
"""
Pre-publication quality check script for dbt-test-results package.

This script performs comprehensive validation to ensure the package is
ready for publication on GitHub and dbt Hub.
"""

import os
import sys
import json
import yaml
import re
from pathlib import Path
from typing import Dict, List, Tuple, Optional

class PublicationChecker:
    def __init__(self, package_root: str):
        self.package_root = Path(package_root)
        self.errors = []
        self.warnings = []
        self.info = []
        
    def check_all(self) -> bool:
        """Run all publication checks."""
        print("🔍 Running pre-publication checks for dbt-test-results...")
        print("=" * 60)
        
        # Core checks
        self.check_package_structure()
        self.check_dbt_project_metadata()
        self.check_documentation()
        self.check_macro_quality()
        self.check_examples()
        self.check_version_consistency()
        self.check_license()
        self.check_security()
        
        # Report results
        self.print_results()
        
        return len(self.errors) == 0
    
    def check_package_structure(self):
        """Validate package follows dbt conventions."""
        print("\n📁 Checking package structure...")
        
        required_files = [
            "dbt_project.yml",
            "README.md", 
            "CHANGELOG.md",
            "LICENSE"
        ]
        
        required_dirs = [
            "macros",
            "examples",
            "integration_tests"
        ]
        
        for file in required_files:
            if not (self.package_root / file).exists():
                self.errors.append(f"Missing required file: {file}")
            else:
                self.info.append(f"✓ Found {file}")
        
        for dir in required_dirs:
            if not (self.package_root / dir).exists():
                self.errors.append(f"Missing required directory: {dir}")
            else:
                self.info.append(f"✓ Found {dir}/")
        
        # Check macro files
        macro_files = list((self.package_root / "macros").glob("*.sql"))
        if len(macro_files) < 5:
            self.warnings.append(f"Only {len(macro_files)} macro files found")
        else:
            self.info.append(f"✓ Found {len(macro_files)} macro files")
    
    def check_dbt_project_metadata(self):
        """Validate dbt_project.yml has all required metadata."""
        print("\n⚙️ Checking dbt_project.yml metadata...")
        
        try:
            with open(self.package_root / "dbt_project.yml", 'r') as f:
                project = yaml.safe_load(f)
        except Exception as e:
            self.errors.append(f"Failed to parse dbt_project.yml: {e}")
            return
        
        required_fields = [
            "name", "version", "description", "author", 
            "license", "repository", "homepage"
        ]
        
        for field in required_fields:
            if field not in project:
                self.errors.append(f"Missing required field in dbt_project.yml: {field}")
            else:
                self.info.append(f"✓ Found {field}: {project[field]}")
        
        # Validate version format
        if "version" in project:
            version = project["version"]
            if not re.match(r'^\d+\.\d+\.\d+$', version):
                self.errors.append(f"Invalid version format: {version} (should be X.Y.Z)")
            else:
                self.info.append(f"✓ Valid version format: {version}")
        
        # Check dependencies
        if "dependencies" in project:
            deps = project["dependencies"]
            if len(deps) == 0:
                self.warnings.append("No dependencies declared")
            else:
                self.info.append(f"✓ Found {len(deps)} dependencies")
        else:
            self.warnings.append("No dependencies section found")
    
    def check_documentation(self):
        """Validate documentation quality."""
        print("\n📖 Checking documentation...")
        
        # Main README
        readme_path = self.package_root / "README.md"
        if readme_path.exists():
            content = readme_path.read_text()
            
            # Check for required sections (flexible matching)
            required_sections = [
                ("installation", ["installation", "install", "quick start"]),
                ("configuration", ["configuration", "config"]), 
                ("examples", ["examples", "example"]),
                ("troubleshooting", ["troubleshooting", "troubleshoot", "issues"]),
                ("contributing", ["contributing", "contribute", "development"])
            ]
            
            missing_sections = []
            for section_name, section_variants in required_sections:
                found = any(variant.lower() in content.lower() for variant in section_variants)
                if not found:
                    missing_sections.append(section_name)
            
            if missing_sections:
                self.warnings.append(f"README missing sections: {', '.join(missing_sections)}")
            else:
                self.info.append("✓ README has all recommended sections")
            
            # Check length
            if len(content) < 5000:
                self.warnings.append(f"README is quite short ({len(content)} chars)")
            else:
                self.info.append(f"✓ README is comprehensive ({len(content)} chars)")
        
        # Example documentation
        examples_dir = self.package_root / "examples"
        if examples_dir.exists():
            example_readmes = list(examples_dir.glob("*/README.md"))
            if len(example_readmes) < 2:
                self.warnings.append("Few example README files found")
            else:
                self.info.append(f"✓ Found {len(example_readmes)} example READMEs")
    
    def check_macro_quality(self):
        """Check macro code quality."""
        print("\n🔧 Checking macro quality...")
        
        macros_dir = self.package_root / "macros"
        if not macros_dir.exists():
            return
        
        macro_files = list(macros_dir.glob("*.sql"))
        total_lines = 0
        documented_macros = 0
        
        for macro_file in macro_files:
            content = macro_file.read_text()
            total_lines += len(content.splitlines())
            
            # Check for documentation blocks
            if content.count("{#") > 0:
                documented_macros += 1
            
            # Check for common issues
            if "{{ log(" in content and "dbt_test_results.log_message" not in content:
                self.warnings.append(f"Using raw log() in {macro_file.name}")
            
            # Check for error handling
            has_error_handling = any(pattern in content for pattern in [
                "exceptions.raise_compiler_error",
                "handle_error",
                "handle_enhanced_error",
                "dbt_test_results.handle",
                "try", "except", "catch"
            ])
            
            if not has_error_handling and macro_file.name != "utils.sql":
                self.warnings.append(f"Limited error handling in {macro_file.name}")
        
        self.info.append(f"✓ {total_lines} total lines of macro code")
        self.info.append(f"✓ {documented_macros}/{len(macro_files)} macros documented")
        
        if documented_macros < len(macro_files):
            self.warnings.append("Not all macros have documentation blocks")
    
    def check_examples(self):
        """Validate example projects."""
        print("\n🚀 Checking examples...")
        
        examples_dir = self.package_root / "examples"
        if not examples_dir.exists():
            return
        
        example_dirs = [d for d in examples_dir.iterdir() if d.is_dir()]
        
        for example_dir in example_dirs:
            dbt_project = example_dir / "dbt_project.yml"
            readme = example_dir / "README.md"
            
            # Skip configurations directory - it contains config templates, not a dbt project
            if example_dir.name == "configurations":
                self.info.append(f"✓ Configurations directory contains templates")
                continue
            
            if not dbt_project.exists():
                self.errors.append(f"Example {example_dir.name} missing dbt_project.yml")
            else:
                # Validate example dbt_project.yml
                try:
                    with open(dbt_project, 'r') as f:
                        project = yaml.safe_load(f)
                    
                    if "dbt_test_results" not in project.get("vars", {}):
                        self.warnings.append(f"Example {example_dir.name} missing dbt_test_results vars")
                    else:
                        self.info.append(f"✓ Example {example_dir.name} properly configured")
                except Exception as e:
                    self.errors.append(f"Invalid dbt_project.yml in {example_dir.name}: {e}")
            
            if not readme.exists():
                self.warnings.append(f"Example {example_dir.name} missing README.md")
    
    def check_version_consistency(self):
        """Check version consistency across files."""
        print("\n🔢 Checking version consistency...")
        
        versions = {}
        
        # dbt_project.yml
        try:
            with open(self.package_root / "dbt_project.yml", 'r') as f:
                project = yaml.safe_load(f)
                versions["dbt_project.yml"] = project.get("version")
        except Exception:
            pass
        
        # CHANGELOG.md
        changelog_path = self.package_root / "CHANGELOG.md"
        if changelog_path.exists():
            content = changelog_path.read_text()
            # Look for version patterns like [1.0.0] or ## 1.0.0
            version_matches = re.findall(r'[\[\#\s](\d+\.\d+\.\d+)[\]\s\-]', content)
            if version_matches:
                versions["CHANGELOG.md"] = version_matches[0]
        
        # Check consistency
        unique_versions = set(v for v in versions.values() if v)
        if len(unique_versions) > 1:
            self.errors.append(f"Version mismatch: {versions}")
        elif len(unique_versions) == 1:
            self.info.append(f"✓ Consistent version across files: {list(unique_versions)[0]}")
    
    def check_license(self):
        """Validate license file."""
        print("\n📄 Checking license...")
        
        license_path = self.package_root / "LICENSE"
        if license_path.exists():
            content = license_path.read_text()
            
            if "MIT License" in content:
                self.info.append("✓ MIT License detected")
            elif "Apache" in content:
                self.info.append("✓ Apache License detected")
            else:
                self.warnings.append("License type not clearly identified")
            
            current_year = "2024"  # or datetime.now().year
            if current_year not in content:
                self.warnings.append(f"License may need year update")
        
    def check_security(self):
        """Basic security checks."""
        print("\n🔒 Checking security...")
        
        # Check for hardcoded secrets
        security_patterns = [
            r'password\s*=\s*["\'][^"\']+["\']',
            r'api_key\s*=\s*["\'][^"\']+["\']',
            r'secret\s*=\s*["\'][^"\']+["\']',
            r'token\s*=\s*["\'][^"\']+["\']'
        ]
        
        issues_found = 0
        for file_path in self.package_root.rglob("*.sql"):
            content = file_path.read_text()
            for pattern in security_patterns:
                if re.search(pattern, content, re.IGNORECASE):
                    self.warnings.append(f"Potential hardcoded secret in {file_path}")
                    issues_found += 1
        
        if issues_found == 0:
            self.info.append("✓ No obvious hardcoded secrets found")
        
        # Check for SQL injection patterns
        injection_patterns = [
            r'["\'][^"\']*["\']\s*\+\s*[a-zA-Z_][a-zA-Z0-9_]*',  # String + variable concatenation
            r'format\s*\([^)]*[a-zA-Z_][a-zA-Z0-9_]*',          # String formatting with variables
        ]
        
        injection_issues = 0
        for file_path in self.package_root.rglob("*.sql"):
            content = file_path.read_text()
            
            # Skip integration test files and dbt test macros
            if "/integration_tests/" in str(file_path) or "{% test " in content:
                continue
                
            for pattern in injection_patterns:
                matches = re.findall(pattern, content)
                if matches and "escape_sql_string" not in content and "dbt_test_results.escape" not in content:
                    injection_issues += 1
                    self.warnings.append(f"Potential SQL injection in {file_path.name}: {matches[0][:50]}...")
        
        if injection_issues == 0:
            self.info.append("✓ No obvious SQL injection patterns found")
    
    def print_results(self):
        """Print validation results."""
        print("\n" + "=" * 60)
        print("📋 VALIDATION RESULTS")
        print("=" * 60)
        
        if self.errors:
            print(f"\n❌ ERRORS ({len(self.errors)}):")
            for error in self.errors:
                print(f"   • {error}")
        
        if self.warnings:
            print(f"\n⚠️  WARNINGS ({len(self.warnings)}):")
            for warning in self.warnings:
                print(f"   • {warning}")
        
        if self.info:
            print(f"\n✅ SUCCESS ({len(self.info)}):")
            for info in self.info:
                print(f"   • {info}")
        
        print("\n" + "=" * 60)
        
        if len(self.errors) == 0:
            if len(self.warnings) == 0:
                print("🎉 READY FOR PUBLICATION! No issues found.")
                grade = "A+"
            elif len(self.warnings) <= 3:
                print("✅ READY FOR PUBLICATION! Minor warnings only.")
                grade = "A"
            else:
                print("⚠️  MOSTLY READY. Consider addressing warnings.")
                grade = "B+"
        else:
            print("❌ NOT READY. Please fix errors before publication.")
            grade = "C"
        
        print(f"📊 Quality Grade: {grade}")
        print("=" * 60)

def main():
    """Main entry point."""
    package_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    
    checker = PublicationChecker(package_root)
    success = checker.check_all()
    
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()