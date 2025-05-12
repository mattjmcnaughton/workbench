#!/usr/bin/env bash
#
# packages.ubuntu-2404.sh - Install and configure development tools for Ubuntu 24.04
#
# This script sets up a complete development environment on Ubuntu 24.04 by installing
# and configuring essential development tools, language servers, and utilities. It is
# designed to be idempotent and can be run multiple times safely.
#
# Usage:
#   packages.ubuntu-2404.sh [install|clean|verify|help]
#
# Commands:
#   install     Install all development tools (default)
#   clean       Remove specific tool or all tools
#   verify      Verify all installations are working
#   help        Show help message
#
# Clean targets:
#   neovim, nodejs, golang, uv, rust, pyright, gopls,
#   lua-language-server, claude-code, python-tools, all
#
# Environment Variables:
#   GIT_NAME                Git author name (default: mattjmcnaughton)
#   GIT_EMAIL               Git author email (default: me@mattjmcnaughton)
#   NEOVIM_VERSION          Neovim version to install (default: v0.11.1)
#   NODE_VERSION            Node.js version to install (default: v22.15.0)
#   GO_VERSION              Go version to install (default: 1.24.1)
#   UV_VERSION              uv version to install (default: 0.6.17)
#   PYTHON_VERSION          Python version to install (default: 3.12)
#   LUA_LANGUAGE_SERVER_VERSION  Lua language server version (default: 3.14.0)
#
# Examples:
#   # Install all tools with default versions
#   ./packages.ubuntu-2404.sh install
#
#   # Install with custom Python version
#   PYTHON_VERSION=3.11 ./packages.ubuntu-2404.sh install
#
#   # Clean specific tool
#   ./packages.ubuntu-2404.sh clean nodejs
#
#   # Verify all installations
#   ./packages.ubuntu-2404.sh verify
#
# Exit Codes:
#   0 - Success
#   1 - General error
#   2 - Invalid arguments
#   3 - Installation failed
#   4 - Verification failed
#
# Dependencies:
#   - Ubuntu 24.04 or compatible
#   - sudo access
#   - Internet connection
#   - curl or wget
#
# Notes:
#   - Script must be run with sudo for system-wide installations
#   - Some tools are installed in user space (~/.local)
#   - Git configuration is set globally
#   - PATH is updated in ~/.bash_profile

set -euo pipefail
IFS=$'\n\t'

# Default configuration - can be overridden with environment variables
GIT_NAME="${GIT_NAME:-mattjmcnaughton}"
GIT_EMAIL="${GIT_EMAIL:-me@mattjmcnaughton}"
NEOVIM_VERSION="${NEOVIM_VERSION:-v0.11.1}"
NODE_VERSION="${NODE_VERSION:-v22.15.0}"
GO_VERSION="${GO_VERSION:-1.24.1}"
UV_VERSION="${UV_VERSION:-0.6.17}"
PYTHON_VERSION="${PYTHON_VERSION:-3.12}"
LUA_LANGUAGE_SERVER_VERSION="${LUA_LANGUAGE_SERVER_VERSION:-3.14.0}"

# Check if running on Ubuntu 24.04
check_os() {
    if [[ ! -f /etc/os-release ]]; then
        log_error "Cannot determine operating system: /etc/os-release not found"
        exit 1
    fi

    # Source the os-release file
    # shellcheck source=/dev/null
    . /etc/os-release

    if [[ "$ID" != "ubuntu" ]]; then
        log_error "This script only supports Ubuntu. Found: $ID"
        exit 1
    fi

    if [[ "$VERSION_ID" != "24.04" ]]; then
        log_error "This script only supports Ubuntu 24.04. Found: $VERSION_ID"
        exit 1
    fi

    log_info "Detected Ubuntu 24.04"
}

# Logging functions
log() {
    local level="$1"
    shift
    echo "$(date +"%Y-%m-%d %H:%M:%S") [$level] $*"
}

log_info()  { log "INFO" "$@"; }
log_warn()  { log "WARN" "$@"; }
log_error() { log "ERROR" "$@" >&2; }

# Update bash profile with environment variable
update_bash_profile() {
    local key="$1"
    local value="$2"
    local bash_profile="$HOME/.bash_profile"
    local line="export $key=$value"

    # Create bash_profile if it doesn't exist
    touch "$bash_profile"

    # Check if the exact key-value pair already exists
    if grep -q "^$line$" "$bash_profile"; then
        log_info "Environment variable $key=$value already set in $bash_profile"
        return
    fi

    # Add new line
    echo "$line" >> "$bash_profile"
    log_info "Updated $key in $bash_profile"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if package is installed
package_installed() {
    dpkg -l | grep -q "^ii  $1 "
}

# Install base packages (requires root)
install_base_packages() {
    log_info "Installing base packages..."

    # Update package list
    sudo apt update

    # Base packages to install
    local packages=(
        build-essential
        curl
        dnsutils
        gettext
        git
        gzip
        iputils-ping
        just
        lsof
        ripgrep
        tar
        tmux
        tree
        unzip
        wget
        xz-utils
        cmake
        fzf
        fd-find
        rustup
        luarocks
    )

    # Check and install only missing packages
    local to_install=()
    for pkg in "${packages[@]}"; do
        if ! package_installed "$pkg"; then
            to_install+=("$pkg")
        fi
    done

    if [ ${#to_install[@]} -gt 0 ]; then
        sudo DEBIAN_FRONTEND=noninteractive apt install -y "${to_install[@]}"
    else
        log_info "All base packages already installed"
    fi
}

# Install Neovim
install_neovim() {
    if command_exists nvim && [[ "$(nvim --version | head -1)" == *"$NEOVIM_VERSION"* ]]; then
        log_info "Neovim $NEOVIM_VERSION already installed"
        return
    fi

    log_info "Installing Neovim $NEOVIM_VERSION..."
    cd /tmp
    wget "https://github.com/neovim/neovim/releases/download/$NEOVIM_VERSION/nvim-linux-x86_64.tar.gz"
    tar xzf nvim-linux-x86_64.tar.gz
    sudo cp -r nvim-linux-x86_64/* /usr/local/
    rm -rf nvim-linux-x86_64 nvim-linux-x86_64.tar.gz
    cd -
}

# Install Node.js
install_nodejs() {
    # Update PATH in bash_profile
    update_bash_profile "PATH" "/usr/local/lib/nodejs/node-${NODE_VERSION}-linux-x64/bin:\$PATH"
    export PATH="/usr/local/lib/nodejs/node-${NODE_VERSION}-linux-x64/bin:$PATH"

    if command_exists node && [[ "$(node --version)" == "$NODE_VERSION" ]]; then
        log_info "Node.js $NODE_VERSION already installed"
        return
    fi

    log_info "Installing Node.js $NODE_VERSION..."
    cd /tmp
    wget "https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-linux-x64.tar.xz"
    sudo mkdir -p /usr/local/lib/nodejs
    sudo tar -xJf "node-${NODE_VERSION}-linux-x64.tar.xz" -C /usr/local/lib/nodejs
    rm "node-${NODE_VERSION}-linux-x64.tar.xz"
    cd -
}

# Install Go
install_golang() {
    # Update PATH in bash_profile
    update_bash_profile "PATH" "\$PATH:/usr/local/go/bin"
    export PATH="$PATH:/usr/local/go/bin"

    if command_exists go && [[ "$(go version)" == *"go$GO_VERSION"* ]]; then
        log_info "Go $GO_VERSION already installed"
        return
    fi

    log_info "Installing Go $GO_VERSION..."
    cd /tmp
    wget "https://golang.org/dl/go$GO_VERSION.linux-amd64.tar.gz"
    sudo tar -C /usr/local -xzf "go$GO_VERSION.linux-amd64.tar.gz"
    rm "go$GO_VERSION.linux-amd64.tar.gz"
    cd -
}

# Install uv
install_uv() {
    if command_exists uv && [[ "$(uv --version)" == *"$UV_VERSION"* ]]; then
        log_info "uv $UV_VERSION already installed"
        return
    fi

    log_info "Installing uv $UV_VERSION..."
    cd /tmp
    wget "https://github.com/astral-sh/uv/releases/download/$UV_VERSION/uv-x86_64-unknown-linux-gnu.tar.gz"
    tar -xzf uv-x86_64-unknown-linux-gnu.tar.gz
    sudo cp uv-x86_64-unknown-linux-gnu/* /usr/local/bin/
    rm -rf uv-x86_64-unknown-linux-gnu*
    cd -
}

# User-space installations
setup_user_environment() {
    log_info "Setting up user environment..."

    # Configure npm to install to ~/.local
    npm config set prefix "$HOME/.local"

    # Update PATH in bash_profile
    update_bash_profile "PATH" "\$PATH:$HOME/.local/bin"
    export PATH="$PATH:$HOME/.local/bin"

    # Install pyright if not present
    if ! command_exists pyright; then
        log_info "Installing pyright..."
        npm install -g pyright
    fi

    # Install rust toolchain if not present
    if ! rustup show | grep -q "stable-gnu"; then
        log_info "Installing Rust stable toolchain..."
        rustup toolchain install stable-gnu
    fi

    # Update PATH in bash_profile
    update_bash_profile "PATH" "\$PATH:$HOME/.cargo/bin"
    export PATH="$PATH:$HOME/.cargo/bin"

    # Install Python and tools via uv
    if ! uv python list | grep -q "$PYTHON_VERSION"; then
        log_info "Installing Python $PYTHON_VERSION..."
        uv python install "$PYTHON_VERSION"
    fi

    # uv uses `.local/bin` for tools, so already configured.

    # Install Python tools
    if ! command_exists ruff; then
        log_info "Installing ruff..."
        uv tool install ruff
    fi

    if ! command_exists pre-commit; then
        log_info "Installing pre-commit..."
        uv tool install pre-commit
    fi

    # Install Go tools
    update_bash_profile "GOPATH" "$HOME/.go"
    export GOPATH="$HOME/.go"

    # Update PATH in bash_profile
    update_bash_profile "PATH" "\$PATH:$HOME/.go/bin"
    export PATH="$PATH:$HOME/.go/bin"

    if ! command_exists gopls; then
        log_info "Installing gopls..."
        go install golang.org/x/tools/gopls@latest
    fi

    # Install lua-language-server
    if ! command_exists lua-language-server; then
        log_info "Installing lua-language-server $LUA_LANGUAGE_SERVER_VERSION..."
        cd /tmp
        wget "https://github.com/LuaLS/lua-language-server/releases/download/$LUA_LANGUAGE_SERVER_VERSION/lua-language-server-$LUA_LANGUAGE_SERVER_VERSION-linux-x64.tar.gz"
        mkdir -p "$HOME/.local/share/lua-language-server"
        tar -C "$HOME/.local/share/lua-language-server" -xzf "lua-language-server-$LUA_LANGUAGE_SERVER_VERSION-linux-x64.tar.gz"
        ln -sf "$HOME/.local/share/lua-language-server/bin/lua-language-server" "$HOME/.local/bin/lua-language-server"
        rm "lua-language-server-$LUA_LANGUAGE_SERVER_VERSION-linux-x64.tar.gz"
        cd -
    fi

    # Install Claude Code
    if ! command_exists claude; then
        log_info "Installing Claude Code..."
        npm install -g @anthropic-ai/claude-code
        claude config add ignorePatterns ".env.*" ".git" "node_modules" "dist"
        claude config set --global theme dark
    fi

    # Set Git environment variables
    update_bash_profile "GIT_AUTHOR_NAME" "$GIT_NAME"
    update_bash_profile "GIT_AUTHOR_EMAIL" "$GIT_EMAIL"
    update_bash_profile "GIT_COMMITTER_NAME" "$GIT_NAME"
    update_bash_profile "GIT_COMMITTER_EMAIL" "$GIT_EMAIL"
}

# Verify installations
verify_installations() {
    log_info "Verifying installations..."

    local failed=0

    if ! nvim --version >/dev/null 2>&1; then
        log_error "Neovim not working properly"
        failed=1
    fi

    if ! cargo --version >/dev/null 2>&1; then
        log_error "Cargo not working properly"
        failed=1
    fi

    if ! node --version >/dev/null 2>&1; then
        log_error "Node not working properly"
        failed=1
    fi

    if ! npm --version >/dev/null 2>&1; then
        log_error "npm not working properly"
        failed=1
    fi

    if ! uv --version >/dev/null 2>&1; then
        log_error "uv not working properly"
        failed=1
    fi

    if ! uv run --python "$PYTHON_VERSION" python --version >/dev/null 2>&1; then
        log_error "Python not working properly"
        failed=1
    fi

    if ! uvx ruff --version >/dev/null 2>&1; then
        log_error "ruff not working properly"
        failed=1
    fi

    if ! uvx pre-commit --version >/dev/null 2>&1; then
        log_error "pre-commit not working properly"
        failed=1
    fi

    if ! go help >/dev/null 2>&1; then
        log_error "Go not working properly"
        failed=1
    fi

    if ! gopls help >/dev/null 2>&1; then
        log_error "gopls not working properly"
        failed=1
    fi

    if ! pyright --version >/dev/null 2>&1; then
        log_error "pyright not working properly"
        failed=1
    fi

    if ! lua-language-server --version >/dev/null 2>&1; then
        log_error "lua-language-server not working properly"
        failed=1
    fi

    if [[ $failed -eq 0 ]]; then
        log_info "All installations verified successfully!"
    else
        log_error "Some installations failed verification"
        exit 1
    fi
}

# Clean specific tool
clean_tool() {
    local tool="$1"

    case "$tool" in
        "neovim")
            log_info "Removing Neovim..."
            sudo rm -rf /usr/local/bin/nvim /usr/local/share/nvim
            ;;
        "nodejs")
            log_info "Removing Node.js..."
            sudo rm -rf /usr/local/lib/nodejs
            npm config delete prefix
            ;;
        "golang")
            log_info "Removing Go..."
            sudo rm -rf /usr/local/go
            ;;
        "uv")
            log_info "Removing uv..."
            sudo rm -f /usr/local/bin/uv
            ;;
        "rust")
            log_info "Removing Rust..."
            rustup self uninstall -y
            ;;
        "pyright")
            log_info "Removing pyright..."
            npm uninstall -g pyright
            ;;
        "gopls")
            log_info "Removing gopls..."
            rm -f "$HOME/.go/bin/gopls"
            ;;
        "lua-language-server")
            log_info "Removing lua-language-server..."
            rm -rf "$HOME/.local/share/lua-language-server"
            rm -f "$HOME/.local/bin/lua-language-server"
            ;;
        "claude-code")
            log_info "Removing Claude Code..."
            npm uninstall -g @anthropic-ai/claude-code
            ;;
        "python-tools")
            log_info "Removing Python tools..."
            uv tool uninstall ruff
            uv tool uninstall pre-commit
            ;;
        "all")
            log_info "Removing all installed tools..."
            clean_tool "neovim"
            clean_tool "nodejs"
            clean_tool "golang"
            clean_tool "uv"
            clean_tool "rust"
            clean_tool "pyright"
            clean_tool "gopls"
            clean_tool "lua-language-server"
            clean_tool "claude-code"
            clean_tool "python-tools"
            ;;
        *)
            log_error "Unknown tool: $tool"
            log_info "Available tools: neovim, nodejs, golang, uv, rust, pyright, gopls, lua-language-server, claude-code, python-tools, all"
            exit 1
            ;;
    esac
}

# Main function
main() {
    local action="${1:-install}"

    # Check OS before proceeding
    check_os

    case "$action" in
        "install")
            log_info "Starting installation..."
            install_base_packages
            install_neovim
            install_nodejs
            install_golang
            install_uv
            setup_user_environment
            verify_installations
            log_info "Installation completed successfully!"
            log_info "Please source ~/.bash_profile or start a new shell to ensure PATH is updated"
            ;;
        "clean")
            if [[ $# -lt 2 ]]; then
                log_error "Usage: $0 clean <tool|all>"
                exit 1
            fi
            clean_tool "$2"
            ;;
        "verify")
            verify_installations
            ;;
        "help"|"--help"|"-h")
            echo "Usage: $0 [install|clean|verify|help]"
            echo ""
            echo "Commands:"
            echo "  install     Install all development tools (default)"
            echo "  clean       Remove specific tool or all tools"
            echo "  verify      Verify all installations are working"
            echo "  help        Show this help message"
            echo ""
            echo "Clean targets:"
            echo "  neovim, nodejs, golang, uv, rust, pyright, gopls,"
            echo "  lua-language-server, claude-code, python-tools, all"
            echo ""
            echo "Environment variables:"
            echo "  GIT_NAME, GIT_EMAIL, NEOVIM_VERSION, NODE_VERSION,"
            echo "  GO_VERSION, UV_VERSION, PYTHON_VERSION,"
            echo "  LUA_LANGUAGE_SERVER_VERSION"
            ;;
        *)
            log_error "Unknown action: $action"
            log_info "Usage: $0 [install|clean|verify|help]"
            exit 1
            ;;
    esac
}

# Run main
main "$@"
