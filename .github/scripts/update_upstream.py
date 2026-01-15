#!/usr/bin/env python3
"""
Script to check for Prysm upstream updates and update mainnet package files.
This script:
1. Fetches the latest release from OffchainLabs/prysm
2. Compares with the current upstream version
3. Updates dappnode_package-mainnet.json and build/docker-compose-mainnet.yml if needed
"""

import json
import os
import re
import sys
import urllib.request
from typing import Dict, Optional, Tuple


def fetch_latest_release(repo_owner: str, repo_name: str) -> Optional[str]:
    """
    Fetch the latest release tag from GitHub repository.
    
    Args:
        repo_owner: The owner of the repository
        repo_name: The name of the repository
        
    Returns:
        The latest release tag name (e.g., 'v7.1.1') or None if not found
    """
    url = f"https://api.github.com/repos/{repo_owner}/{repo_name}/releases/latest"
    
    try:
        # Use GitHub token if available (in GitHub Actions)
        request = urllib.request.Request(url)
        github_token = os.getenv('GITHUB_TOKEN')
        if github_token:
            request.add_header('Authorization', f'Bearer {github_token}')
        
        with urllib.request.urlopen(request) as response:
            data = json.loads(response.read().decode())
            return data.get('tag_name')
    except Exception as e:
        print(f"Error fetching latest release: {e}", file=sys.stderr)
        return None


def parse_version(version_str: str) -> Tuple[int, int, int]:
    """
    Parse a version string like '0.0.68' into a tuple of integers.
    
    Args:
        version_str: Version string to parse
        
    Returns:
        Tuple of (major, minor, patch)
        
    Raises:
        ValueError: If the version string is not in the expected format
    """
    try:
        parts = version_str.split('.')
        if len(parts) != 3:
            raise ValueError(f"Version must have 3 parts (major.minor.patch), got {len(parts)}")
        return tuple(int(p) for p in parts)
    except ValueError as e:
        raise ValueError(f"Invalid version string '{version_str}': {e}")


def increment_patch_version(version_str: str) -> str:
    """
    Increment the patch version.
    
    Args:
        version_str: Version string like '0.0.68'
        
    Returns:
        Incremented version string like '0.0.69'
    """
    major, minor, patch = parse_version(version_str)
    return f"{major}.{minor}.{patch + 1}"


def update_dappnode_package(file_path: str, new_version: str, new_upstream: str) -> bool:
    """
    Update the dappnode_package-mainnet.json file.
    
    Args:
        file_path: Path to the dappnode_package-mainnet.json file
        new_version: New package version
        new_upstream: New upstream version
        
    Returns:
        True if file was updated, False otherwise
    """
    try:
        with open(file_path, 'r') as f:
            data = json.load(f)
        
        data['version'] = new_version
        data['upstream'] = new_upstream
        
        with open(file_path, 'w') as f:
            json.dump(data, f, indent=2)
            f.write('\n')  # Add newline at end of file
        
        return True
    except Exception as e:
        print(f"Error updating {file_path}: {e}", file=sys.stderr)
        return False


def update_docker_compose(file_path: str, new_version: str, new_upstream: str) -> bool:
    """
    Update the build/docker-compose-mainnet.yml file.
    
    Args:
        file_path: Path to the docker-compose-mainnet.yml file
        new_version: New package version (for image tag)
        new_upstream: New upstream version (for VERSION build arg)
        
    Returns:
        True if file was updated, False otherwise
    """
    try:
        with open(file_path, 'r') as f:
            content = f.read()
        
        original_content = content
        
        # Update image tag
        content = re.sub(
            r"(image:\s+['\"]eth2validator\.avado\.dnp\.dappnode\.eth:)[\d\.]+(['\"])",
            rf"\g<1>{new_version}\g<2>",
            content
        )
        
        # Update VERSION build argument
        content = re.sub(
            r"(VERSION:\s+)v[\d\.]+",
            rf"\g<1>{new_upstream}",
            content
        )
        
        # Verify that changes were made
        if content == original_content:
            print(f"Warning: No changes made to {file_path}. Pattern may not match.", file=sys.stderr)
            return False
        
        with open(file_path, 'w') as f:
            f.write(content)
        
        return True
    except Exception as e:
        print(f"Error updating {file_path}: {e}", file=sys.stderr)
        return False


def main():
    """Main function to check and update Prysm versions."""
    
    # Paths to files
    package_file = "dappnode_package-mainnet.json"
    compose_file = "build/docker-compose-mainnet.yml"
    
    # Read current versions
    try:
        with open(package_file, 'r') as f:
            package_data = json.load(f)
        
        current_version = package_data.get('version')
        current_upstream = package_data.get('upstream')
        
        print(f"Current package version: {current_version}")
        print(f"Current upstream version: {current_upstream}")
    except Exception as e:
        print(f"Error reading {package_file}: {e}", file=sys.stderr)
        sys.exit(1)
    
    # Fetch latest release from OffchainLabs/prysm
    latest_release = fetch_latest_release("OffchainLabs", "prysm")
    
    if not latest_release:
        print("Could not fetch latest release", file=sys.stderr)
        sys.exit(1)
    
    print(f"Latest upstream version: {latest_release}")
    
    # Compare versions
    if latest_release == current_upstream:
        print("Already up to date!")
        # Set output for GitHub Actions
        if os.getenv('GITHUB_OUTPUT'):
            with open(os.getenv('GITHUB_OUTPUT'), 'a') as f:
                f.write(f"update_available=false\n")
        sys.exit(0)
    
    # Calculate new version
    new_package_version = increment_patch_version(current_version)
    new_upstream_version = latest_release
    
    print(f"Updating to:")
    print(f"  Package version: {new_package_version}")
    print(f"  Upstream version: {new_upstream_version}")
    
    # Update files
    success = True
    
    if not update_dappnode_package(package_file, new_package_version, new_upstream_version):
        success = False
    
    if not update_docker_compose(compose_file, new_package_version, new_upstream_version):
        success = False
    
    if not success:
        print("Failed to update files", file=sys.stderr)
        sys.exit(1)
    
    print("Files updated successfully!")
    
    # Set outputs for GitHub Actions
    if os.getenv('GITHUB_OUTPUT'):
        with open(os.getenv('GITHUB_OUTPUT'), 'a') as f:
            f.write(f"update_available=true\n")
            f.write(f"old_version={current_version}\n")
            f.write(f"new_version={new_package_version}\n")
            f.write(f"old_upstream={current_upstream}\n")
            f.write(f"new_upstream={new_upstream_version}\n")
    
    # Also set environment variables for compatibility
    if os.getenv('GITHUB_ENV'):
        with open(os.getenv('GITHUB_ENV'), 'a') as f:
            f.write(f"UPDATE_AVAILABLE=true\n")
            f.write(f"OLD_VERSION={current_version}\n")
            f.write(f"NEW_VERSION={new_package_version}\n")
            f.write(f"OLD_UPSTREAM={current_upstream}\n")
            f.write(f"NEW_UPSTREAM={new_upstream_version}\n")


if __name__ == "__main__":
    main()
