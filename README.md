# workbench

A lightweight development environment management tool that combines dotfile management with a simple package management system.

## Overview

Workbench serves two primary purposes:

1. **Dotfile Management**: Centralizes and manages your development tool configurations (dotfiles) across different machines, including:
   - Neovim configuration
   - Git configuration
   - Tmux configuration
   - Bash configuration (bashrc and aliases)

2. **Development Package Management**: Provides a simple, script-based approach to managing development tools and dependencies, currently supporting:
   - Ubuntu 24.04 LTS
   - Core development tools (git, tmux, etc.)
   - Language runtimes and tools:
     - Node.js
     - Go
     - Python (via uv)
     - Rust
     - Lua
   - Development tools:
     - Neovim
     - Language servers
     - Build tools

## Features

### Dotfile Management
- Centralized configuration management
- Easy synchronization across machines
- Simple symlink-based setup
- Version controlled configurations

### Package Management
- Lightweight bash-based installation
- Idempotent installations (safe to run multiple times)
- Configurable via environment variables
- Supports both system and user-space installations
- Automatic version management for key tools

## Quick Start

1. Bootstrap credentials (this sets up necessary authentication for the target machine):
   ```bash
   just bootstrap-creds your-username@target-host
   ```
   This step ensures you have the necessary credentials and SSH access to the target machine.

2. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/workbench.git ~/.workbench
   ```

   Alternatively, if you haven't set up SSH keys yet, you can use rsync to bootstrap the repository:
   ```bash
   just bootstrap-rsync your-username@target-host ~/.workbench
   ```
   (Use `just bootstrap-rsync-dry` to preview what would be synced)

3. Set up dotfiles first (this ensures any package installations can use your custom configurations):
   ```bash
   cd ~/.workbench
   ./config/symlink-dotfiles.sh
   ```

4. Install packages (Ubuntu 24.04):
   ```bash
   ./install/packages.ubuntu-2404.sh
   ```

5. Getting to work!

    TODO: Document how to use w/ Cursor, Zed, VSCode, NeoVim (both local and remote).

Note: It's important to set up dotfiles before installing packages because some package installations may depend on or use your custom configurations (like git config, bash aliases, etc.).

## Configuration

### Package Management
Customize the installation by setting environment variables:
```bash
# Example customizations
export NEOVIM_VERSION="v0.11.1"
export NODE_VERSION="v22.15.0"
export GO_VERSION="1.24.1"
export PYTHON_VERSION="3.12"
```

## Contributing

We welcome contributions! Here's how to get started:

### Development Setup

1. Fork and clone the repository
2. Make your changes
3. Test your changes using our Docker-based test environment

### Testing Changes

We provide a Docker-based test environment to verify changes to the package installation script. This ensures that the script works correctly in a clean Ubuntu 24.04 environment.

To test your changes:

1. Build and run the test environment locally:
   ```bash
   just test-integration
   ```

This will:
- Build a Docker container using `Dockerfile.test`
- Create a non-root user with sudo privileges
- Run the package installation script
- Verify that all tools install correctly

The test environment uses Ubuntu 24.04 and runs the script as a non-root user, simulating a real-world installation scenario.

Note: All pull requests are automatically tested using GitHub Actions. The integration test runs on every PR to ensure changes work correctly in a clean environment. You can also manually trigger the test from the Actions tab in GitHub.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

Copyright (c) 2025 [mattjmcnaughton](https://github.com/mattjmcnaughton)
