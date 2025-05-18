#!/usr/bin/env python3
"""
Secret Transfer Manager

A lightweight, dependency-free tool for securely transferring secrets between machines.
This script intentionally uses only Python's standard library to ensure maximum
portability and minimal setup requirements. No external dependencies are required
or allowed.

Key Features:
    - Zero external dependencies (uses only Python standard library)
    - Secure transfer of AWS, SSH, and GPG secrets
    - Dry run capability
    - Selective transfer of specific secret types
    - Automatic permission management

Usage:
    # Transfer all secret types
    ./push_secrets.py --all --target user@target-machine

    # Transfer specific secret types
    ./push_secrets.py --limit aws,ssh --target user@target-machine

    # Dry run mode
    ./push_secrets.py --all --target user@target-machine --dry-run
"""

import argparse
import logging
import subprocess
import sys
from pathlib import Path
from typing import List

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="[%(levelname)s] %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)],
)
logger = logging.getLogger(__name__)


class SecretManager:
    SECRET_TYPES = {"aws", "ssh", "gpg"}

    # Mapping of secret types to their paths and permissions
    SECRET_CONFIGS = {
        "aws": {
            "source": Path.home() / ".aws",
            "target": "~/.aws",
            "permissions": "chmod 600 ~/.aws/*",
        },
        "ssh": {
            "source": Path.home() / ".ssh",
            "target": "~/.ssh",
            "permissions": "chmod 600 ~/.ssh/id_* && chmod 644 ~/.ssh/*.pub && chmod 600 ~/.ssh/known_hosts",
        },
        "gpg": {
            "source": Path.home() / ".gnupg",
            "target": "~/.gnupg",
            "permissions": "chmod 700 ~/.gnupg && chmod 600 ~/.gnupg/*",
        },
    }

    def __init__(self, target_host: str, dry_run: bool = False):
        self.target_host = target_host
        self.dry_run = dry_run

    def validate_secret_types(self, types: List[str]) -> None:
        """Validate that all specified secret types are supported."""
        invalid_types = set(types) - self.SECRET_TYPES
        if invalid_types:
            raise ValueError(
                f"Invalid secret types: {', '.join(invalid_types)}. "
                f"Valid types are: {', '.join(sorted(self.SECRET_TYPES))}"
            )

    def transfer_secrets(self, types: List[str]) -> None:
        """Transfer the specified secret types to the target machine."""
        if self.dry_run:
            logger.info("Dry run mode - would transfer the following secret types:")
            for type_ in types:
                logger.info(f"  - {type_}")
            return

        for type_ in types:
            config = self.SECRET_CONFIGS[type_]
            source = config["source"]
            target = f"{self.target_host}:{config['target']}"

            if not source.exists():
                logger.warning(f"Source directory {source} does not exist")
                continue

            logger.info(f"Transferring {type_} secrets from {source} to {target}...")

            # Use rsync to transfer files
            try:
                # subprocess.run arguments explained:
                # - ["rsync", "-av", "--checksum", f"{source}/", f"{target}/"]: Command and args
                #   - rsync: The rsync command for efficient file transfer
                #   - -a: Archive mode (preserves permissions, timestamps, etc.)
                #   - -v: Verbose output for better visibility
                #   - --checksum: Use checksums instead of file size/time for comparison
                #   - f"{source}/": Source directory with trailing slash to copy contents
                #   - f"{target}/": Target directory with trailing slash
                # - check=True: Raise CalledProcessError if command fails
                # - capture_output=True: Capture stdout/stderr instead of printing to terminal
                # - text=True: Return captured output as strings instead of bytes
                subprocess.run(
                    ["rsync", "-av", "--checksum", f"{source}/", f"{target}/"],
                    check=True,
                    capture_output=True,
                    text=True,
                )
            except subprocess.CalledProcessError as e:
                logger.error(f"Error transferring {type_} secrets: {e.stderr}")
                continue

            # Set permissions on target machine
            try:
                subprocess.run(
                    ["ssh", self.target_host, config["permissions"]],
                    check=True,
                    capture_output=True,
                    text=True,
                )
            except subprocess.CalledProcessError as e:
                logger.error(f"Error setting permissions for {type_}: {e.stderr}")


def main():
    parser = argparse.ArgumentParser(description="Transfer secrets to a target machine")
    parser.add_argument("--all", action="store_true", help="Transfer all secret types")
    parser.add_argument(
        "--limit", help="Comma-separated list of secret types to transfer (aws,ssh,gpg)"
    )
    parser.add_argument(
        "--target", required=True, help="Target machine in format user@host"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be transferred without making changes",
    )

    args = parser.parse_args()

    if not args.all and not args.limit:
        parser.error("Either --all or --limit must be specified")

    try:
        manager = SecretManager(args.target, args.dry_run)

        if args.all:
            types_to_transfer = list(SecretManager.SECRET_TYPES)
        else:
            types_to_transfer = [t.strip() for t in args.limit.split(",")]
            manager.validate_secret_types(types_to_transfer)

        manager.transfer_secrets(types_to_transfer)

    except ValueError as e:
        logger.error(f"Error: {e}")
        sys.exit(1)
    except KeyboardInterrupt:
        logger.error("\nOperation cancelled by user")
        sys.exit(1)


if __name__ == "__main__":
    main()
