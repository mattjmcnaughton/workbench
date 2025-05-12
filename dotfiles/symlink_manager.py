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
    - Local/Remote IDE configuration support

Usage:
    # Symlink all dotfiles
    ./symlink_manager.py --all

    # Symlink specific dotfiles
    ./symlink_manager.py --limit git,tmux

    # Exclude specific dotfiles
    ./symlink_manager.py --all --exclude nvim

    # Custom symlink mapping
    ./symlink_manager.py --map nvim:nvim-minimal
    ./symlink_manager.py --map "nvim:nvim-minimal,git:git-work"

    # Configure IDE for local/remote usage
    ./symlink_manager.py --ide-mode local    # Configure for local development (default)

Custom Mapping Examples:
    The --map option allows you to override the default source paths for specific
    dotfiles. This is useful for maintaining multiple configurations for the same
    tool. For example:

    1. Different Neovim configurations:
       ./symlink_manager.py --map nvim:nvim-minimal
       This would symlink:
       ~/.config/nvim -> ./dotfiles/nvim-minimal/
       Instead of the default:
       ~/.config/nvim -> ./dotfiles/nvim/

    2. Multiple Git configurations:
       ./symlink_manager.py --map git:git-work
       This would symlink:
       ~/.gitconfig -> ./dotfiles/git-work/.gitconfig
       Instead of the default:
       ~/.gitconfig -> ./dotfiles/git/.gitconfig

    3. Multiple mappings at once:
       ./symlink_manager.py --map "nvim:nvim-minimal,git:git-work"
       This would apply both mappings simultaneously.

IDE Configuration Modes:
    The --ide-mode option allows you to configure IDE settings for local development.
    Each IDE maintains a single configuration that is symlinked to local paths:

    Local Mode (--ide-mode local):
       Symlinks IDE configurations to local paths:
       - VSCode: ~/.config/Code/User/
       - Cursor: ~/.config/cursor/
       - Zed: ~/.config/zed/

    Note: Remote mode support has been removed as it's still a work in progress
    and may not be a good idea. The remote paths were:
    - VSCode: ~/.vscode-server/data/User/
    - Cursor: ~/.cursor-server/data/
    - Zed: ~/.zed-server/data/

    Directory Structure Example:
    dotfiles/
    ├── nvim/              # Default Neovim config
    ├── nvim-minimal/      # Minimal Neovim config
    ├── nvim-full/         # Full-featured Neovim config
    ├── git/               # Default Git config
    ├── git-work/          # Work-specific Git config
    └── git-personal/      # Personal Git config
    └── vscode/            # Single VSCode configuration
    └── cursor/            # Single Cursor configuration
    └── zed/               # Single Zed configuration

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
import os
import sys
import platform
from enum import Enum
from pathlib import Path
from typing import List, Dict, Set


class IDEMode(Enum):
    LOCAL = "local"  # Only local mode is supported for now
    # Remote mode removed as it's WIP and may not be a good idea


def get_default_config_dir() -> Path:
    """Get the platform-specific default config directory."""
    system = platform.system().lower()
    if system == "darwin":  # macOS
        return Path.home() / "Library" / "Application Support"
    elif system == "linux":
        return Path.home() / ".config"
    else:
        # Default to .config for other platforms, but warn
        print(
            f"Warning: Unsupported platform {system}, defaulting to ~/.config",
            file=sys.stderr,
        )
        return Path.home() / ".config"


class DotfilesManager:
    def __init__(self, dotfiles_dir: Path, ide_mode: IDEMode = IDEMode.LOCAL):
        self.dotfiles_dir = dotfiles_dir
        self.home_dir = Path.home()
        self.ide_mode = ide_mode
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
            "git": {
                "source": self.dotfiles_dir / "git" / "config",
                "target": self.home_dir / ".git" / "config",
            },
            "tmux": {
                "source": self.dotfiles_dir / "tmux" / "tmux.conf",
                "target": self.home_dir / "tmux" / "tmux.conf",
            },
            "nvim": {
                "source": self.dotfiles_dir / "nvim",
                "target": self.config_dir / "nvim",
            },
        }

        # IDE configurations with local/remote target paths
        ide_configs = {
            "vscode": {
                "source": self.dotfiles_dir / "vscode",
                "local_target": self.config_dir / "Code" / "User",
            },
            "cursor": {
                "source": self.dotfiles_dir / "cursor",
                "local_target": self.config_dir / "Cursor" / "User",
            },
            "zed": {
                "source": self.dotfiles_dir / "zed",
                "local_target": self.config_dir / "zed"
            }
        }

        # Add IDE configurations based on mode
        # Only local mode is supported
        for ide, config in ide_configs.items():
            self.config_mapping[ide] = {
                "source": config["source"],
                "target": config["local_target"],
            }

    def symlink_all(self, exclude: Set[str] = None) -> None:
        """Create symlinks for all dotfiles except those in exclude."""
        exclude = exclude or set()
        for name, mapping in self.config_mapping.items():
            if name not in exclude:
                self._create_symlink(mapping["source"], mapping["target"])

    def symlink_specific(self, dotfiles: List[str], exclude: Set[str] = None) -> None:
        """Create symlinks only for specified dotfiles."""
        exclude = exclude or set()
        for name in dotfiles:
            if name in self.config_mapping and name not in exclude:
                mapping = self.config_mapping[name]
                self._create_symlink(mapping["source"], mapping["target"])

    def _create_symlink(self, source: Path, target: Path) -> None:
        """Create a symlink from source to target, handling existing files."""
        if not source.exists():
            print(f"Warning: Source {source} does not exist", file=sys.stderr)
            return

        # Create parent directories if they don't exist
        target.parent.mkdir(parents=True, exist_ok=True)

        # Handle existing files/symlinks
        if target.exists():
            if target.is_symlink():
                target.unlink()
            else:
                backup = target.with_suffix(".backup")
                print(f"Backing up existing {target} to {backup}")
                target.rename(backup)

        try:
            target.symlink_to(source)
            print(f"Created symlink: {target} -> {source}")
        except Exception as e:
            print(f"Error creating symlink {target}: {e}", file=sys.stderr)


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
    parser.add_argument(
        "--ide-mode",
        choices=[mode.value for mode in IDEMode],
        default=IDEMode.LOCAL.value,
        help="Configure IDE settings for local development (remote mode is WIP and disabled)",
    )

    args = parser.parse_args()

    # Get the directory where this script is located
    script_dir = Path(__file__).parent
    manager = DotfilesManager(script_dir, IDEMode(args.ide_mode))

    exclude = set(args.exclude.split(",")) if args.exclude else set()

    if args.all:
        manager.symlink_all(exclude)
    elif args.limit:
        dotfiles = [d.strip() for d in args.limit.split(",")]
        manager.symlink_specific(dotfiles, exclude)
    else:
        parser.print_help()
        sys.exit(1)


if __name__ == "__main__":
    main()
