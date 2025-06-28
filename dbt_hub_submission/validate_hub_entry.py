#!/usr/bin/env python3
"""
JSON validation tool for dbt Hub submission.

This script validates the hub.json entry format and checks for common issues
before submitting to the hubcap repository.
"""

import json
import sys
import re
from typing import Dict, List, Any, Optional

class HubEntryValidator:
    def __init__(self):
        self.errors = []
        self.warnings = []
        self.info = []
    
    def validate_json_syntax(self, json_content: str) -> bool:
        """Validate basic JSON syntax."""
        try:
            parsed = json.loads(json_content)
            self.info.append("✅ JSON syntax is valid")
            return True
        except json.JSONDecodeError as e:
            self.errors.append(f"❌ JSON syntax error: {e}")
            return False
    
    def validate_hub_entry_format(self, entry_content: str, github_username: str) -> bool:
        """Validate the specific hub.json entry format."""
        try:
            entry = json.loads(entry_content)
            
            # Check if it's a dictionary
            if not isinstance(entry, dict):
                self.errors.append("❌ Entry must be a JSON object (dictionary)")
                return False
            
            # Check if username exists as key
            if github_username not in entry:
                self.errors.append(f"❌ GitHub username '{github_username}' not found in entry")
                return False
            
            # Check if packages is a list
            packages = entry[github_username]
            if not isinstance(packages, list):
                self.errors.append(f"❌ Packages for '{github_username}' must be a list")
                return False
            
            # Check for dbt-test-results
            if "dbt-test-results" not in packages:
                self.errors.append("❌ 'dbt-test-results' not found in packages list")
                return False
            
            # Check alphabetical ordering within packages
            sorted_packages = sorted(packages)
            if packages != sorted_packages:
                self.warnings.append("⚠️ Packages are not in alphabetical order")
                self.info.append(f"   Current: {packages}")
                self.info.append(f"   Should be: {sorted_packages}")
            else:
                self.info.append("✅ Packages are in alphabetical order")
            
            self.info.append(f"✅ Entry format is valid for '{github_username}'")
            return True
            
        except json.JSONDecodeError as e:
            self.errors.append(f"❌ JSON parsing error: {e}")
            return False
    
    def validate_github_username(self, username: str) -> bool:
        """Validate GitHub username format."""
        # GitHub username rules: 1-39 characters, alphanumeric or hyphens, no consecutive hyphens
        pattern = r'^[a-zA-Z0-9](?:[a-zA-Z0-9]|-(?=[a-zA-Z0-9])){0,38}$'
        
        if not re.match(pattern, username):
            self.errors.append(f"❌ Invalid GitHub username format: '{username}'")
            self.info.append("   GitHub usernames must be 1-39 characters, alphanumeric or hyphens")
            return False
        
        if len(username) > 39:
            self.errors.append(f"❌ GitHub username too long: {len(username)} characters (max 39)")
            return False
        
        if username.startswith('-') or username.endswith('-'):
            self.errors.append(f"❌ GitHub username cannot start or end with hyphen: '{username}'")
            return False
        
        if '--' in username:
            self.errors.append(f"❌ GitHub username cannot have consecutive hyphens: '{username}'")
            return False
        
        self.info.append(f"✅ GitHub username format is valid: '{username}'")
        return True
    
    def check_alphabetical_position(self, username: str, sample_usernames: List[str]) -> None:
        """Check where the username should be positioned alphabetically."""
        all_usernames = sample_usernames + [username]
        sorted_usernames = sorted(all_usernames)
        
        position = sorted_usernames.index(username)
        
        if position == 0:
            self.info.append(f"📍 '{username}' should be positioned at the beginning")
        elif position == len(sorted_usernames) - 1:
            self.info.append(f"📍 '{username}' should be positioned at the end")
        else:
            before = sorted_usernames[position - 1]
            after = sorted_usernames[position + 1]
            self.info.append(f"📍 '{username}' should be positioned between '{before}' and '{after}'")
    
    def generate_sample_entry(self, username: str, existing_packages: List[str] = None) -> str:
        """Generate a sample hub.json entry."""
        if existing_packages:
            packages = sorted(existing_packages + ["dbt-test-results"])
        else:
            packages = ["dbt-test-results"]
        
        entry = {username: packages}
        return json.dumps(entry, indent=4)
    
    def print_results(self):
        """Print validation results."""
        print("🔍 dbt Hub Entry Validation Results")
        print("=" * 50)
        
        if self.errors:
            print(f"\n❌ ERRORS ({len(self.errors)}):")
            for error in self.errors:
                print(f"   {error}")
        
        if self.warnings:
            print(f"\n⚠️ WARNINGS ({len(self.warnings)}):")
            for warning in self.warnings:
                print(f"   {warning}")
        
        if self.info:
            print(f"\n✅ INFO ({len(self.info)}):")
            for info in self.info:
                print(f"   {info}")
        
        print("\n" + "=" * 50)
        
        if len(self.errors) == 0:
            if len(self.warnings) == 0:
                print("🎉 READY FOR SUBMISSION! No issues found.")
                grade = "Perfect"
            else:
                print("✅ READY FOR SUBMISSION! Only minor warnings.")
                grade = "Good"
        else:
            print("❌ NOT READY. Please fix errors before submission.")
            grade = "Needs Work"
        
        print(f"📊 Validation Grade: {grade}")

def main():
    """Main validation function."""
    print("🚀 dbt Hub Entry Validator")
    print("=" * 30)
    
    # Get GitHub username
    if len(sys.argv) > 1:
        github_username = sys.argv[1]
    else:
        github_username = input("Enter your GitHub username: ").strip()
    
    validator = HubEntryValidator()
    
    # Validate GitHub username format
    username_valid = validator.validate_github_username(github_username)
    
    if not username_valid:
        validator.print_results()
        return 1
    
    # Generate sample entry
    print(f"\n📝 Generating sample hub.json entry for '{github_username}'...")
    sample_entry = validator.generate_sample_entry(github_username)
    
    print("Sample entry:")
    print("-" * 20)
    print(sample_entry)
    print("-" * 20)
    
    # Validate the generated entry
    validator.validate_hub_entry_format(sample_entry, github_username)
    
    # Check alphabetical positioning with sample usernames
    sample_usernames = [
        "Aaron-Zhou", "Aidbox", "dbt-labs", "fishtown-analytics", 
        "calogica", "datatonic", "montreal-analytics"
    ]
    validator.check_alphabetical_position(github_username, sample_usernames)
    
    # Provide integration instructions
    print(f"\n📋 Integration Instructions:")
    print(f"1. Fork the hubcap repository: https://github.com/dbt-labs/hubcap")
    print(f"2. Find the correct alphabetical position for '{github_username}' in hub.json")
    print(f"3. Add the following entry:")
    print(f"   {json.dumps({github_username: ['dbt-test-results']})}")
    print(f"4. Validate the complete hub.json file")
    print(f"5. Create a pull request")
    
    # Print final results
    validator.print_results()
    
    return 0 if len(validator.errors) == 0 else 1

def validate_file(file_path: str, github_username: str) -> int:
    """Validate an existing JSON file."""
    try:
        with open(file_path, 'r') as f:
            content = f.read()
        
        validator = HubEntryValidator()
        
        # Validate JSON syntax
        if not validator.validate_json_syntax(content):
            validator.print_results()
            return 1
        
        # Validate hub entry format
        validator.validate_hub_entry_format(content, github_username)
        validator.print_results()
        
        return 0 if len(validator.errors) == 0 else 1
        
    except FileNotFoundError:
        print(f"❌ File not found: {file_path}")
        return 1
    except Exception as e:
        print(f"❌ Error reading file: {e}")
        return 1

if __name__ == "__main__":
    if len(sys.argv) > 2 and sys.argv[1] == "--file":
        # Validate existing file
        file_path = sys.argv[2]
        github_username = sys.argv[3] if len(sys.argv) > 3 else input("Enter GitHub username: ").strip()
        sys.exit(validate_file(file_path, github_username))
    else:
        # Interactive validation
        sys.exit(main())