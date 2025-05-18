# Workbench

A collection of development tools and configurations to help streamline your development workflow.

## Components

### Dotfiles Management

A robust dotfiles management system that allows for easy configuration and
deployment of development environment settings across different machines and
contexts.

For detailed documentation, see [dotfiles/README.md](dotfiles/README.md).

### Package Management

A lightweight, bash-based package management system for development tools and dependencies. Currently supports Ubuntu 24.04 LTS.

For detailed documentation, see [install/README.md](install/README.md).

## Quick Start

1. Bootstrap credentials (this sets up necessary authentication for the target machine):
   ```bash
   ./bootstrap/push_secrets.py $ARGS
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
   cd dotfiles
   ./symlink_manager.py $ARGS
   ```

4. Install packages

- Install homebrew (needed on both Mac and Linux) via instructions on [Homebrew](https://brew.sh/).
- Run an install script based on OS (i.e. `install/ubuntu-2404/install.py`).

## Contributing

Note: All pull requests are automatically tested using GitHub Actions. The integration test runs on every PR to ensure changes work correctly in a clean environment.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

Copyright (c) 2025 [mattjmcnaughton](https://github.com/mattjmcnaughton)
