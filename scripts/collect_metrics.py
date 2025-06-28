#!/usr/bin/env python3
"""
Community Metrics Collection Script for dbt-test-results

This script collects various metrics about package adoption and community engagement
while respecting user privacy and only using publicly available information.
"""

import os
import json
import csv
import requests
from datetime import datetime, timedelta
from typing import Dict, List, Any
from pathlib import Path

# Configuration
REPO_OWNER = "your-org"  # Replace with actual GitHub organization
REPO_NAME = "dbt-test-results"
METRICS_DIR = Path("metrics")
GITHUB_TOKEN = os.environ.get("GITHUB_TOKEN")

class MetricsCollector:
    """Collect and store community metrics for dbt-test-results package"""
    
    def __init__(self):
        self.session = requests.Session()
        if GITHUB_TOKEN:
            self.session.headers.update({
                "Authorization": f"token {GITHUB_TOKEN}",
                "Accept": "application/vnd.github.v3+json"
            })
        
        # Ensure metrics directory exists
        METRICS_DIR.mkdir(exist_ok=True)
    
    def collect_github_metrics(self) -> Dict[str, Any]:
        """Collect GitHub repository metrics"""
        print("Collecting GitHub repository metrics...")
        
        repo_url = f"https://api.github.com/repos/{REPO_OWNER}/{REPO_NAME}"
        
        try:
            repo_data = self.session.get(repo_url).json()
            
            # Basic repository stats
            metrics = {
                'timestamp': datetime.now().isoformat(),
                'stars': repo_data.get('stargazers_count', 0),
                'forks': repo_data.get('forks_count', 0),
                'watchers': repo_data.get('watchers_count', 0),
                'open_issues': repo_data.get('open_issues_count', 0),
                'size_kb': repo_data.get('size', 0),
                'default_branch': repo_data.get('default_branch', 'main')
            }
            
            # Recent activity (last 7 days)
            one_week_ago = (datetime.now() - timedelta(days=7)).isoformat()
            
            # New issues
            issues_url = f"{repo_url}/issues"
            issues_params = {'since': one_week_ago, 'state': 'all'}
            issues_response = self.session.get(issues_url, params=issues_params)
            
            if issues_response.status_code == 200:
                new_issues = [issue for issue in issues_response.json() 
                            if 'pull_request' not in issue]  # Filter out PRs
                metrics['new_issues_week'] = len(new_issues)
            else:
                metrics['new_issues_week'] = 0
            
            # New pull requests
            prs_url = f"{repo_url}/pulls"
            prs_params = {'state': 'all', 'sort': 'created', 'direction': 'desc'}
            prs_response = self.session.get(prs_url, params=prs_params)
            
            if prs_response.status_code == 200:
                recent_prs = [
                    pr for pr in prs_response.json()
                    if datetime.fromisoformat(pr['created_at'].replace('Z', '+00:00')) > 
                       datetime.fromisoformat(one_week_ago)
                ]
                metrics['new_prs_week'] = len(recent_prs)
            else:
                metrics['new_prs_week'] = 0
            
            # Contributors (approximate from recent commits)
            commits_url = f"{repo_url}/commits"
            commits_params = {'since': one_week_ago}
            commits_response = self.session.get(commits_url, params=commits_params)
            
            if commits_response.status_code == 200:
                commits = commits_response.json()
                unique_authors = set(
                    commit['author']['login'] if commit['author'] else 'unknown'
                    for commit in commits
                )
                metrics['active_contributors_week'] = len(unique_authors)
            else:
                metrics['active_contributors_week'] = 0
            
            print(f"✅ GitHub metrics collected: {metrics['stars']} stars, {metrics['forks']} forks")
            return metrics
            
        except Exception as e:
            print(f"❌ Error collecting GitHub metrics: {e}")
            return {'timestamp': datetime.now().isoformat(), 'error': str(e)}
    
    def collect_release_metrics(self) -> Dict[str, Any]:
        """Collect release and version adoption metrics"""
        print("Collecting release metrics...")
        
        releases_url = f"https://api.github.com/repos/{REPO_OWNER}/{REPO_NAME}/releases"
        
        try:
            releases_response = self.session.get(releases_url)
            
            if releases_response.status_code != 200:
                return {'error': f"Failed to fetch releases: {releases_response.status_code}"}
            
            releases = releases_response.json()
            
            metrics = {
                'timestamp': datetime.now().isoformat(),
                'total_releases': len(releases),
                'latest_release': releases[0]['tag_name'] if releases else None,
                'latest_release_date': releases[0]['published_at'] if releases else None
            }
            
            # Download counts for recent releases
            download_counts = {}
            for release in releases[:5]:  # Last 5 releases
                tag_name = release['tag_name']
                total_downloads = sum(
                    asset['download_count'] for asset in release.get('assets', [])
                )
                download_counts[tag_name] = total_downloads
            
            metrics['download_counts'] = download_counts
            metrics['total_downloads'] = sum(download_counts.values())
            
            print(f"✅ Release metrics collected: {len(releases)} releases, {metrics['total_downloads']} total downloads")
            return metrics
            
        except Exception as e:
            print(f"❌ Error collecting release metrics: {e}")
            return {'timestamp': datetime.now().isoformat(), 'error': str(e)}
    
    def collect_community_metrics(self) -> Dict[str, Any]:
        """Collect community engagement metrics"""
        print("Collecting community engagement metrics...")
        
        try:
            metrics = {
                'timestamp': datetime.now().isoformat()
            }
            
            # GitHub Discussions (if enabled)
            discussions_url = f"https://api.github.com/repos/{REPO_OWNER}/{REPO_NAME}/discussions"
            discussions_response = self.session.get(discussions_url)
            
            if discussions_response.status_code == 200:
                discussions = discussions_response.json()
                
                # Count recent discussions (last 30 days)
                thirty_days_ago = datetime.now() - timedelta(days=30)
                recent_discussions = [
                    d for d in discussions
                    if datetime.fromisoformat(d['created_at'].replace('Z', '+00:00')) > thirty_days_ago
                ]
                
                metrics['discussions_total'] = len(discussions)
                metrics['discussions_recent_30d'] = len(recent_discussions)
            else:
                metrics['discussions_total'] = 0
                metrics['discussions_recent_30d'] = 0
            
            # Traffic data (requires push access)
            traffic_url = f"https://api.github.com/repos/{REPO_OWNER}/{REPO_NAME}/traffic/views"
            traffic_response = self.session.get(traffic_url)
            
            if traffic_response.status_code == 200:
                traffic_data = traffic_response.json()
                metrics['page_views_14d'] = traffic_data.get('count', 0)
                metrics['unique_visitors_14d'] = traffic_data.get('uniques', 0)
            else:
                metrics['page_views_14d'] = 0
                metrics['unique_visitors_14d'] = 0
            
            # Clone statistics
            clones_url = f"https://api.github.com/repos/{REPO_OWNER}/{REPO_NAME}/traffic/clones"
            clones_response = self.session.get(clones_url)
            
            if clones_response.status_code == 200:
                clones_data = clones_response.json()
                metrics['clones_14d'] = clones_data.get('count', 0)
                metrics['unique_cloners_14d'] = clones_data.get('uniques', 0)
            else:
                metrics['clones_14d'] = 0
                metrics['unique_cloners_14d'] = 0
            
            print(f"✅ Community metrics collected: {metrics['discussions_total']} discussions, {metrics['page_views_14d']} page views")
            return metrics
            
        except Exception as e:
            print(f"❌ Error collecting community metrics: {e}")
            return {'timestamp': datetime.now().isoformat(), 'error': str(e)}
    
    def save_metrics_csv(self, metrics: Dict[str, Any], filename: str) -> None:
        """Save metrics to CSV file"""
        filepath = METRICS_DIR / f"{filename}.csv"
        
        # Check if file exists to determine if we need headers
        file_exists = filepath.exists()
        
        with open(filepath, 'a', newline='') as csvfile:
            writer = csv.DictWriter(csvfile, fieldnames=metrics.keys())
            
            if not file_exists:
                writer.writeheader()
            
            writer.writerow(metrics)
        
        print(f"📁 Metrics saved to {filepath}")
    
    def save_metrics_json(self, metrics: Dict[str, Any], filename: str) -> None:
        """Save metrics to JSON file (for complex data structures)"""
        filepath = METRICS_DIR / f"{filename}.json"
        
        # Load existing data if file exists
        data = []
        if filepath.exists():
            with open(filepath, 'r') as f:
                data = json.load(f)
        
        # Append new metrics
        data.append(metrics)
        
        # Save updated data
        with open(filepath, 'w') as f:
            json.dump(data, f, indent=2)
        
        print(f"📁 Metrics saved to {filepath}")
    
    def generate_summary_report(self) -> str:
        """Generate a summary report of current metrics"""
        report_lines = [
            f"# dbt-test-results Community Metrics Report",
            f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')}",
            "",
        ]
        
        # Try to read latest metrics
        try:
            github_csv = METRICS_DIR / "github_metrics.csv"
            if github_csv.exists():
                with open(github_csv, 'r') as f:
                    reader = csv.DictReader(f)
                    rows = list(reader)
                    if rows:
                        latest = rows[-1]
                        report_lines.extend([
                            "## GitHub Repository Metrics",
                            f"- Stars: {latest.get('stars', 'N/A')}",
                            f"- Forks: {latest.get('forks', 'N/A')}",
                            f"- Watchers: {latest.get('watchers', 'N/A')}",
                            f"- Open Issues: {latest.get('open_issues', 'N/A')}",
                            f"- New Issues (7d): {latest.get('new_issues_week', 'N/A')}",
                            f"- New PRs (7d): {latest.get('new_prs_week', 'N/A')}",
                            f"- Active Contributors (7d): {latest.get('active_contributors_week', 'N/A')}",
                            ""
                        ])
            
            community_csv = METRICS_DIR / "community_metrics.csv"
            if community_csv.exists():
                with open(community_csv, 'r') as f:
                    reader = csv.DictReader(f)
                    rows = list(reader)
                    if rows:
                        latest = rows[-1]
                        report_lines.extend([
                            "## Community Engagement",
                            f"- GitHub Discussions: {latest.get('discussions_total', 'N/A')}",
                            f"- Recent Discussions (30d): {latest.get('discussions_recent_30d', 'N/A')}",
                            f"- Page Views (14d): {latest.get('page_views_14d', 'N/A')}",
                            f"- Unique Visitors (14d): {latest.get('unique_visitors_14d', 'N/A')}",
                            f"- Repository Clones (14d): {latest.get('clones_14d', 'N/A')}",
                            ""
                        ])
            
            releases_json = METRICS_DIR / "release_metrics.json"
            if releases_json.exists():
                with open(releases_json, 'r') as f:
                    data = json.load(f)
                    if data:
                        latest = data[-1]
                        report_lines.extend([
                            "## Release Metrics",
                            f"- Total Releases: {latest.get('total_releases', 'N/A')}",
                            f"- Latest Version: {latest.get('latest_release', 'N/A')}",
                            f"- Total Downloads: {latest.get('total_downloads', 'N/A')}",
                            ""
                        ])
        
        except Exception as e:
            report_lines.append(f"Error generating report: {e}")
        
        return "\n".join(report_lines)

def main():
    """Main execution function"""
    print("🚀 Starting dbt-test-results metrics collection...")
    
    collector = MetricsCollector()
    
    # Collect GitHub metrics
    github_metrics = collector.collect_github_metrics()
    if 'error' not in github_metrics:
        collector.save_metrics_csv(github_metrics, 'github_metrics')
    
    # Collect release metrics
    release_metrics = collector.collect_release_metrics()
    if 'error' not in release_metrics:
        collector.save_metrics_json(release_metrics, 'release_metrics')
    
    # Collect community metrics
    community_metrics = collector.collect_community_metrics()
    if 'error' not in community_metrics:
        collector.save_metrics_csv(community_metrics, 'community_metrics')
    
    # Generate summary report
    summary = collector.generate_summary_report()
    summary_path = METRICS_DIR / f"summary_report_{datetime.now().strftime('%Y%m%d')}.md"
    with open(summary_path, 'w') as f:
        f.write(summary)
    
    print(f"📊 Summary report generated: {summary_path}")
    print("✅ Metrics collection completed!")

if __name__ == "__main__":
    main()