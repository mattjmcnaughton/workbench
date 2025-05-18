#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Ubuntu 24.04 Development Environment Setup Script
# Usage: ./install.sh [options]
#
# Options:
#   -h, --help     Show this help message
#
# This script sets up a development environment on Ubuntu 24.04 by installing:
# - System packages (apt)
# - Homebrew packages
# - Rust toolchain
# - Python versions and tools via uv
# - NPX packages

# Logging functions
log_info()  { echo "[INFO] $*"; }
log_warn()  { echo "[WARN] $*" >&2; }
log_error() { echo "[ERROR] $*" >&2; }

# Error handling
trap 'log_error "Script failed at line $LINENO"; exit 1' ERR

# Command existence check
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

require_command() {
    if ! command_exists "$1"; then
        log_error "$1 is required but not installed"
        exit 1
    fi
}

# Show help message
show_help() {
    cat << EOF
Usage: $(basename "$0") [options]

Options:
    -h, --help     Show this help message

This script sets up a development environment on Ubuntu 24.04.
EOF
}

# Function to read package files, handling comments properly
read_packages() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        log_error "Package file not found: $file"
        exit 1
    fi
    grep -v '^#' "$file" | grep -v '^$' | sed 's/[[:space:]]*#.*$//' || true
}

# Install apt packages
install_apt_packages() {
    log_info "Updating package lists..."
    sudo apt update || { log_error "Failed to update package lists"; exit 1; }

    log_info "Installing apt packages..."
    read_packages "$(dirname "$0")/apt.txt" | xargs -r sudo apt install -y || { log_error "Failed to install apt packages"; exit 1; }
}

# Install Homebrew and its packages
install_homebrew() {
    log_info "Installing Homebrew packages..."
    while read -r package; do
        brew install "$package" || { log_error "Failed to install Homebrew package $package"; exit 1; }
    done < <(read_packages "$(dirname "$0")/brew.txt")
}

# Install Rust
install_rust() {
    if ! command_exists rustup; then
        log_error "Rustup not found. Please install Rust toolchain first."
        exit 1
    fi

    log_info "Installing Rust toolchain..."
    rustup toolchain install stable || { log_error "Failed to install Rust toolchain"; exit 1; }
}

install_python() {
    log_info "Installing Python versions..."
    while read -r version; do
        uv python install "$version" || { log_error "Failed to install Python $version"; exit 1; }
    done < <(read_packages "$(dirname "$0")/uv-python.txt")
}

install_python_tools() {
    log_info "Installing Python tools..."
    while read -r tool; do
        uv tool install "$tool" || { log_error "Failed to install Python tool $tool"; exit 1; }
    done < <(read_packages "$(dirname "$0")/uv-tool.txt")
}
# Install NPX packages
install_npx() {
    log_info "Installing NPX packages..."
    while read -r package; do
        npm install -g "$package" || { log_error "Failed to install NPX package $package"; exit 1; }
    done < <(read_packages "$(dirname "$0")/npx.txt")
}

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # Check required commands
    require_command curl
    require_command sudo
    require_command brew

    # Run installations
    install_apt_packages
    install_homebrew
    install_rust
    install_python
    install_python_tools
    install_npx

    log_info "Installation complete!"
}

main "$@"
