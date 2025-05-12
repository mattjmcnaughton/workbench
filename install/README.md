# Package Management System

A lightweight, bash-based package management system for development tools and dependencies. Currently supports Ubuntu 24.04 LTS.

## Overview

This system provides a simple, script-based approach to managing development tools and dependencies. It's designed to be:
- Lightweight (bash-based, no external dependencies)
- Idempotent (safe to run multiple times)
- Configurable (via environment variables)
- Cross-platform (currently Ubuntu 24.04, with plans to support other platforms)

## Directory Structure

```
install/
├── packages.ubuntu-2404.sh    # Main installation script for Ubuntu 24.04
└── tests/                    # Test utilities and fixtures
    └── integration/          # Integration test resources
```

## Usage

### Basic Installation

```bash
# Install all packages
./packages.ubuntu-2404.sh
```

### Configuration

Customize the installation by setting environment variables:

```bash
# Version overrides
export NEOVIM_VERSION="v0.11.1"
export NODE_VERSION="v22.15.0"
export GO_VERSION="1.24.1"
export PYTHON_VERSION="3.12"
```

### Package Categories

1. **Core Development Tools**
   - Git
   - Tmux
   - Basic development utilities

2. **Language Runtimes and Tools**
   - Node.js
   - Go
   - Python (via uv)
   - Rust
   - Lua

3. **Development Tools**
   - Neovim
   - Language servers
   - Build tools

## Testing

The package management system includes a Docker-based test environment to verify installations in a clean Ubuntu 24.04 environment.

```bash
# Run integration tests
just test-integration
```

This will:
1. Build a Docker container using `Dockerfile.test`
2. Create a non-root user with sudo privileges
3. Run the package installation script
4. Verify that all tools install correctly

## Best Practices

1. **Version Management**
   - Use environment variables to specify versions
   - Keep versions in sync across different machines
   - Document version requirements in your project

2. **Installation Order**
   - Install core tools before language-specific tools
   - Install language runtimes before development tools

3. **User Space vs System Installation**
   - Prefer user-space installations when possible
   - Use system installation for tools that require it
   - Document any system-level requirements

4. **Testing**
   - Test installations in a clean environment
   - Verify tool functionality after installation
   - Check for version compatibility

## Notes

- We do not install IDE server components (vscode-server, cursor-server, zed-server, etc.)
- These are managed by the respective editors as needed
- See the main [README.md](../README.md) for information about IDE configuration
