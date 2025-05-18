#!/usr/bin/env python3
"""
Dotfiles Symlink Manager

A lightweight, dependency-free tool for managing dotfiles through symlinks.
This script intentionally uses only Python's standard library to ensure maximum
portability and minimal setup requirements. No external dependencies are required
or allowed.

Key Features:
    - Zero external dependencies (uses only Python standard library)
    - Cross-platform compatibility
    - Automatic backup of existing files
    - Selective symlinking of specific dotfiles
    - Exclusion capability for specific configurations
    - Support for custom symlink mappings

Usage:
    # Symlink all dotfiles
    ./symlink_manager.py --all

    # Symlink specific dotfiles
    ./symlink_manager.py --limit git,tmux

    # Exclude specific dotfiles
    ./symlink_manager.py --all --exclude nvim-with-plugins

Note:
    This script is designed to be as portable as possible. As such, it:
    1. Uses only Python standard library modules
    2. Avoids platform-specific code where possible
    3. Handles paths in a cross-platform manner using pathlib
    4. Provides clear error messages for common issues

Environment Variables:
    CONFIG_DIR            Platform-specific config directory (default: ~/.config on Linux,
                         ~/Library/Application Support on macOS)
"""

import argparse
import logging
import os
import sys
import platform
from pathlib import Path
from typing import List, Dict, Set

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="[%(levelname)s] %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)],
)
logger = logging.getLogger(__name__)


def get_default_config_dir() -> Path:
    """Get the platform-specific default config directory."""
    system = platform.system().lower()
    if system == "darwin":  # macOS
        return Path.home() / "Library" / "Application Support"
    elif system == "linux":
        return Path.home() / ".config"
    else:
        # Default to .config for other platforms, but warn
        logger.warning(f"Unsupported platform {system}, defaulting to ~/.config")
        return Path.home() / ".config"


class DotfilesManager:
    def __init__(self, dotfiles_dir: Path):
        self.dotfiles_dir = dotfiles_dir
        self.home_dir = Path.home()
        # Allow override of config directory via environment variable
        self.config_dir = Path(os.getenv("CONFIG_DIR", str(get_default_config_dir())))
        self.config_mapping: Dict[str, Dict[str, Path]] = {}
        self._load_config_mapping()

    def _load_config_mapping(self):
        """Load the mapping of dotfiles to their target locations."""
        # Default mappings for common dotfiles
        self.config_mapping = {
            "bashrc": {
                "source": self.dotfiles_dir / "bashrc",
                "target": self.home_dir / ".bashrc",
            },
            "bash_aliases": {
                "source": self.dotfiles_dir / "bash_aliases",
                "target": self.home_dir / ".bash_aliases",
            },
            "bash_env": {
                "source": self.dotfiles_dir / "bash_env",
                "target": self.home_dir / ".bash_env",
            },
            "npmrc": {
                "source": self.dotfiles_dir / "npmrc",
                "target": self.home_dir / ".npmrc",
            },
            "git": {
                "source": self.dotfiles_dir / "git" / "config",
                "target": self.home_dir / ".git" / "config",
            },
            "tmux": {
                "source": self.dotfiles_dir / "tmux" / "tmux.conf",
                "target": self.home_dir / "tmux" / "tmux.conf",
            },
            "nvim-plugins": {
                "source": self.dotfiles_dir / "nvim-plugins",
                "target": self.config_dir / "nvim",
            },
            "nvim-no-plugins": {
                "source": self.dotfiles_dir / "nvim-no-plugins",
                "target": self.config_dir / "nvim",
            },
            "vscode": {
                "source": self.dotfiles_dir / "vscode" / "settings.json",
                "target": self.config_dir / "Code" / "User" / "settings.json",
            },
            "cursor": {
                "source": self.dotfiles_dir / "cursor" / "settings.json",
                "target": self.config_dir / "Cursor" / "User" / "settings.json",
            },
        }

    def _check_duplicate_targets(self, dotfiles_to_process: List[str]) -> None:
        """Check if any of the specified dotfiles would create duplicate target paths."""
        target_to_dotfiles: Dict[Path, List[str]] = {}

        for name in dotfiles_to_process:
            if name in self.config_mapping:
                target = self.config_mapping[name]["target"]
                if target in target_to_dotfiles:
                    target_to_dotfiles[target].append(name)
                else:
                    target_to_dotfiles[target] = [name]

        # Find any targets that have multiple dotfiles mapping to them
        duplicates = {
            target: dotfiles
            for target, dotfiles in target_to_dotfiles.items()
            if len(dotfiles) > 1
        }

        if duplicates:
            error_msg = "Found duplicate target paths:\n"
            for target, dotfiles in duplicates.items():
                error_msg += f"  {target} is targeted by: {', '.join(dotfiles)}\n"
            raise ValueError(error_msg)

    def symlink_all(self, exclude: Set[str] = None) -> None:
        """Create symlinks for all dotfiles except those in exclude."""
        exclude = exclude or set()
        dotfiles_to_process = [
            name for name in self.config_mapping.keys() if name not in exclude
        ]
        self._check_duplicate_targets(dotfiles_to_process)
        for name in dotfiles_to_process:
            mapping = self.config_mapping[name]
            self._create_symlink(mapping["source"], mapping["target"])

    def symlink_specific(self, dotfiles: List[str], exclude: Set[str] = None) -> None:
        """Create symlinks only for specified dotfiles."""
        exclude = exclude or set()
        dotfiles_to_process = [
            name
            for name in dotfiles
            if name in self.config_mapping and name not in exclude
        ]
        self._check_duplicate_targets(dotfiles_to_process)
        for name in dotfiles_to_process:
            mapping = self.config_mapping[name]
            self._create_symlink(mapping["source"], mapping["target"])

    def _create_symlink(self, source: Path, target: Path) -> None:
        """Create a symlink from source to target, handling existing files."""
        if not source.exists():
            logger.warning(f"Source {source} does not exist")
            return

        # Create parent directories if they don't exist
        target.parent.mkdir(parents=True, exist_ok=True)

        # Handle existing files/symlinks
        if target.exists():
            if target.is_symlink():
                target.unlink()
            else:
                backup = target.with_suffix(".backup")
                logger.info(f"Backing up existing {target} to {backup}")
                target.rename(backup)

        try:
            target.symlink_to(source)
            logger.info(f"Created symlink: {target} -> {source}")
        except Exception as e:
            logger.error(f"Error creating symlink {target}: {e}")


def main():
    parser = argparse.ArgumentParser(description="Manage dotfiles symlinks")
    parser.add_argument("--all", action="store_true", help="Symlink all dotfiles")
    parser.add_argument(
        "--limit", help="Comma-separated list of specific dotfiles to symlink"
    )
    parser.add_argument("--exclude", help="Comma-separated list of dotfiles to exclude")
    parser.add_argument(
        "--map",
        help="Custom mapping in format dotfile:path (can be used multiple times)",
    )

    args = parser.parse_args()

    # Get the directory where this script is located
    script_dir = Path(__file__).parent
    manager = DotfilesManager(script_dir)

    exclude = set(args.exclude.split(",")) if args.exclude else set()

    try:
        if args.all:
            manager.symlink_all(exclude)
        elif args.limit:
            dotfiles = [d.strip() for d in args.limit.split(",")]
            manager.symlink_specific(dotfiles, exclude)
        else:
            parser.print_help()
            sys.exit(1)
    except ValueError as e:
        logger.error(f"Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
