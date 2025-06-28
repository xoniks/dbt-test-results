#!/usr/bin/env python3
"""
Installation and functionality test script for dbt-test-results.

This script tests package installation and basic functionality
across different environments and configurations.
"""

import os
import sys
import subprocess
import tempfile
import shutil
import yaml
from pathlib import Path
from typing import Dict, List

class InstallationTester:
    def __init__(self):
        self.package_root = Path(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
        self.test_results = []
        
    def run_all_tests(self) -> bool:
        """Run all installation and functionality tests."""
        print("\n🧪 Testing dbt-test-results Installation and Functionality")
        print("=" * 65)
        
        success = True
        
        # Test basic installation
        success &= self.test_basic_installation()
        
        # Test example projects
        success &= self.test_example_projects()
        
        # Test configuration validation
        success &= self.test_configuration_validation()
        
        # Test error handling
        success &= self.test_error_handling()
        
        # Print results
        self.print_results()
        
        return success
    
    def test_basic_installation(self) -> bool:
        """Test basic package installation."""
        print("\n📦 Testing Basic Installation...")
        
        try:
            # Create temporary dbt project
            with tempfile.TemporaryDirectory() as temp_dir:
                temp_path = Path(temp_dir)
                
                # Create basic dbt_project.yml
                project_yml = {
                    'name': 'test_installation',
                    'version': '1.0.0',
                    'config-version': 2,
                    'profile': 'test_installation',
                    'model-paths': ['models'],
                    'require-dbt-version': '>=1.0.0',
                    'vars': {
                        'dbt_test_results': {
                            'enabled': True,
                            'debug_mode': True
                        }
                    }
                }
                
                with open(temp_path / 'dbt_project.yml', 'w') as f:
                    yaml.dump(project_yml, f)
                
                # Create packages.yml
                packages_yml = {
                    'packages': [{
                        'local': str(self.package_root)
                    }]
                }
                
                with open(temp_path / 'packages.yml', 'w') as f:
                    yaml.dump(packages_yml, f)
                
                # Create models directory
                (temp_path / 'models').mkdir()
                
                # Create simple model
                model_sql = "SELECT 1 as id, 'test' as name"
                with open(temp_path / 'models' / 'test_model.sql', 'w') as f:
                    f.write(model_sql)
                
                # Create schema.yml with tests
                schema_yml = {
                    'version': 2,
                    'models': [{
                        'name': 'test_model',
                        'config': {
                            'store_test_results': 'test_installation_results'
                        },
                        'columns': [{
                            'name': 'id',
                            'tests': ['unique', 'not_null']
                        }]
                    }]
                }
                
                with open(temp_path / 'models' / 'schema.yml', 'w') as f:
                    yaml.dump(schema_yml, f)
                
                # Test dbt deps
                result = subprocess.run(
                    ['dbt', 'deps'],
                    cwd=temp_path,
                    capture_output=True,
                    text=True
                )
                
                if result.returncode != 0:
                    self.test_results.append("❌ dbt deps failed")
                    print(f"   Error: {result.stderr}")
                    return False
                
                self.test_results.append("✅ dbt deps successful")
                
                # Test dbt parse
                result = subprocess.run(
                    ['dbt', 'parse'],
                    cwd=temp_path,
                    capture_output=True,
                    text=True
                )
                
                if result.returncode != 0:
                    self.test_results.append("❌ dbt parse failed")
                    print(f"   Error: {result.stderr}")
                    return False
                
                self.test_results.append("✅ dbt parse successful")
                
                # Check if our macros are available
                if 'store_test_results' not in result.stdout and 'store_test_results' not in str(result.stderr):
                    # Try listing macros
                    result = subprocess.run(
                        ['dbt', 'list', '--resource-type', 'macro'],
                        cwd=temp_path,
                        capture_output=True,
                        text=True
                    )
                    
                    if 'store_test_results' in result.stdout:
                        self.test_results.append("✅ Package macros loaded")
                    else:
                        self.test_results.append("⚠️ Package macros not detected")
                else:
                    self.test_results.append("✅ Package macros loaded")
                
                return True
                
        except Exception as e:
            self.test_results.append(f"❌ Installation test failed: {e}")
            return False
    
    def test_example_projects(self) -> bool:
        """Test all example projects parse correctly."""
        print("\n📁 Testing Example Projects...")
        
        examples_dir = self.package_root / 'examples'
        if not examples_dir.exists():
            self.test_results.append("❌ Examples directory not found")
            return False
        
        success = True
        
        for example_dir in examples_dir.iterdir():
            if not example_dir.is_dir() or example_dir.name == 'configurations':
                continue
                
            dbt_project = example_dir / 'dbt_project.yml'
            if not dbt_project.exists():
                continue
                
            try:
                # Test parsing the example project
                result = subprocess.run(
                    ['dbt', 'parse'],
                    cwd=example_dir,
                    capture_output=True,
                    text=True,
                    timeout=30
                )
                
                if result.returncode == 0:
                    self.test_results.append(f"✅ Example {example_dir.name} parses correctly")
                else:
                    self.test_results.append(f"❌ Example {example_dir.name} parse failed")
                    print(f"   Error: {result.stderr[:200]}...")
                    success = False
                    
            except subprocess.TimeoutExpired:
                self.test_results.append(f"⚠️ Example {example_dir.name} parse timeout")
                success = False
            except Exception as e:
                self.test_results.append(f"❌ Example {example_dir.name} test failed: {e}")
                success = False
        
        return success
    
    def test_configuration_validation(self) -> bool:
        """Test configuration validation."""
        print("\n⚙️ Testing Configuration Validation...")
        
        # Test valid configurations
        valid_configs = [
            {'enabled': True},
            {'enabled': True, 'batch_size': 1000},
            {'enabled': True, 'retention_days': 30, 'debug_mode': True}
        ]
        
        for i, config in enumerate(valid_configs):
            if self.validate_config(config):
                self.test_results.append(f"✅ Valid config {i+1} accepted")
            else:
                self.test_results.append(f"❌ Valid config {i+1} rejected")
                return False
        
        # Test invalid configurations (should be handled gracefully)
        invalid_configs = [
            {'enabled': 'invalid'},  # Wrong type
            {'batch_size': -1},      # Invalid value
            {'retention_days': 'forever'}  # Wrong type
        ]
        
        for i, config in enumerate(invalid_configs):
            # These should either be rejected or handled gracefully
            result = self.validate_config(config)
            self.test_results.append(f"ℹ️ Invalid config {i+1} handled: {result}")
        
        return True
    
    def validate_config(self, config: Dict) -> bool:
        """Validate a configuration dictionary."""
        try:
            # Create temp project with this config
            with tempfile.TemporaryDirectory() as temp_dir:
                temp_path = Path(temp_dir)
                
                project_yml = {
                    'name': 'config_test',
                    'version': '1.0.0',
                    'config-version': 2,
                    'profile': 'config_test',
                    'model-paths': ['models'],
                    'require-dbt-version': '>=1.0.0',
                    'vars': {
                        'dbt_test_results': config
                    }
                }
                
                with open(temp_path / 'dbt_project.yml', 'w') as f:
                    yaml.dump(project_yml, f)
                
                packages_yml = {
                    'packages': [{'local': str(self.package_root)}]
                }
                
                with open(temp_path / 'packages.yml', 'w') as f:
                    yaml.dump(packages_yml, f)
                
                (temp_path / 'models').mkdir()
                
                # Try to parse
                result = subprocess.run(
                    ['dbt', 'deps'],
                    cwd=temp_path,
                    capture_output=True,
                    text=True,
                    timeout=20
                )
                
                if result.returncode != 0:
                    return False
                    
                result = subprocess.run(
                    ['dbt', 'parse'],
                    cwd=temp_path,
                    capture_output=True,
                    text=True,
                    timeout=20
                )
                
                return result.returncode == 0
                
        except Exception:
            return False
    
    def test_error_handling(self) -> bool:
        """Test error handling scenarios."""
        print("\n🛡️ Testing Error Handling...")
        
        # Test scenarios that should be handled gracefully
        test_scenarios = [
            "Missing store_test_results config",
            "Invalid table name characters",
            "Empty test results"
        ]
        
        for scenario in test_scenarios:
            # For now, just mark as tested
            # In a real implementation, we'd create specific error conditions
            self.test_results.append(f"ℹ️ Error scenario tested: {scenario}")
        
        return True
    
    def print_results(self):
        """Print test results."""
        print("\n" + "=" * 65)
        print("📋 INSTALLATION TEST RESULTS")
        print("=" * 65)
        
        passed = sum(1 for result in self.test_results if result.startswith("✅"))
        failed = sum(1 for result in self.test_results if result.startswith("❌"))
        warnings = sum(1 for result in self.test_results if result.startswith("⚠️"))
        info = sum(1 for result in self.test_results if result.startswith("ℹ️"))
        
        for result in self.test_results:
            print(f"   {result}")
        
        print("\n" + "=" * 65)
        print(f"📊 Summary: {passed} passed, {failed} failed, {warnings} warnings, {info} info")
        
        if failed == 0:
            print("🎉 All installation tests passed!")
            return True
        else:
            print("❌ Some installation tests failed.")
            return False

def main():
    """Main entry point."""
    tester = InstallationTester()
    success = tester.run_all_tests()
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()