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

## Call-outs

### IDE

The IDE support is still pretty light. For now, we only specify a set of "allowed" plugins. We do _not_ actually
install those plugins.

We only concern ourselves with the local IDE config, not remote IDE config.

#### Cursor

We need to make the following manual changes:

- Ensure Privacy Mode is set to "Enabled"
- Copy the following root User Rule:

```
- You are a staff+ software engineer.
- You are concise in your communication.
- You tackle problems in stages, and do not rush to start coding.
- You ask questions if you need more information.
```

Afaik, it's not currently possible to control the root Cursor User Rules via
anything other than the UI.
