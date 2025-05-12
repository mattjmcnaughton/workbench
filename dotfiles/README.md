# Dotfiles Management System

This directory contains configuration files for various development tools and a management system to easily deploy them across different machines.

## Directory Structure

```
dotfiles/
├── nvim/              # Default Neovim config
├── nvim-minimal/      # Minimal Neovim config
├── nvim-full/         # Full-featured Neovim config
├── git/               # Default Git config
├── git-work/          # Work-specific Git config
├── git-personal/      # Personal Git config
├── vscode/            # Single VSCode configuration
├── cursor/            # Single Cursor configuration
├── zed/               # Single Zed configuration
└── symlink_manager.py # Script to manage symlinks
```

## Usage

The `symlink_manager.py` script provides a simple way to manage your dotfiles:

```bash
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
./symlink_manager.py --ide-mode local    # Configure for local development
./symlink_manager.py --ide-mode remote   # Configure for remote development
./symlink_manager.py --ide-mode both     # Configure for both (default)
```

## Features

- Zero external dependencies (uses only Python standard library)
- Cross-platform compatibility
- Automatic backup of existing files
- Selective symlinking of specific dotfiles
- Exclusion capability for specific configurations
- Support for custom symlink mappings
- Local/Remote IDE configuration support
- Platform-specific config directory handling

## Environment Variables

- `CONFIG_DIR`: Platform-specific config directory
  - Linux: `~/.config` (default)
  - macOS: `~/Library/Application Support` (default)
  - Can be overridden for custom setups

## IDE Configuration Modes

The `--ide-mode` option allows you to configure IDE settings for different development environments. Each IDE maintains a single configuration that is symlinked to different locations based on the mode:

1. **Local Mode** (`--ide-mode local`):
   Symlinks IDE configurations to local paths:
   - VSCode: `~/.config/Code/User/` (Linux) or `~/Library/Application Support/Code/User/` (macOS)
   - Cursor: `~/.config/cursor/` (Linux) or `~/Library/Application Support/cursor/` (macOS)
   - Zed: `~/.config/zed/` (Linux) or `~/Library/Application Support/zed/` (macOS)

2. **Remote Mode** (`--ide-mode remote`):
   Symlinks IDE configurations to remote paths:
   - VSCode: `~/.vscode-server/data/User/`
   - Cursor: `~/.cursor-server/data/`
   - Zed: `~/.zed-server/data/`

3. **Both Mode** (`--ide-mode both`):
   Symlinks IDE configurations to both local and remote paths

## Custom Mapping

The `--map` option allows you to override the default source paths for specific dotfiles. This is useful for maintaining multiple configurations for the same tool. For example:

```bash
# Use minimal Neovim configuration
./symlink_manager.py --map nvim:nvim-minimal

# Use work-specific Git configuration
./symlink_manager.py --map git:git-work

# Apply multiple mappings
./symlink_manager.py --map "nvim:nvim-minimal,git:git-work"
```

## Best Practices

1. Always test configurations in a safe environment first
2. Keep sensitive information (like API keys) out of version control
3. Use conditional configuration when possible to handle different environments
4. Document any special setup requirements in the respective directory's README
5. Use the appropriate IDE mode for your development environment
6. Consider platform-specific paths when sharing configurations across different operating systems

## Adding New Configurations

To add a new configuration:

1. Create a new directory under `dotfiles/` for your configuration
2. Add your configuration files
3. Update the `_load_config_mapping` method in `symlink_manager.py` to include your new configuration

## Best Practices

1. Always test configurations in a safe environment first
2. Keep sensitive information (like API keys) out of version control
3. Use conditional configuration when possible to handle different environments
4. Document any special setup requirements in the respective directory's README
