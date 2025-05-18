#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

log() {
    local level="$1"
    shift
    local timestamp
    timestamp="$(date +"%Y-%m-%d %H:%M:%S")"

    if [[ "$level" == "ERROR" ]]; then
        echo "$timestamp [$level] $*" >&2
    else
        echo "$timestamp [$level] $*"
    fi
}

log_info()  { log "INFO" "$@"; }
log_warn()  { log "WARN" "$@"; }
log_error() { log "ERROR" "$@"; }

trap 'log_error "Script failed"; exit 1' ERR

check_root() {
    if [[ "$(id -u)" -ne 0 ]]; then
        log_error "This script must be run as root"
        exit 1
    fi
    log_info "Running with root privileges"
}

check_tailscale_installed() {
    if command -v tailscale >/dev/null 2>&1; then
        log_info "tailscale is already installed"
        return 0
    fi
    return 1
}

install_tailscale() {
    log_info "Downloading tailscale GPG key"
    curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.gpg | apt-key add -

    log_info "Adding tailscale repo"
    curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.list | tee /etc/apt/sources.list.d/tailscale.list

    log_info "Updating package database"
    apt update

    log_info "Installing tailscale packages"
    apt install -y tailscale

    log_info "Starting and enabling tailscale service"
    systemctl enable --now tailscaled
    log_info "tailscale installation completed successfully"
}

main() {
    log_info "Starting tailscale installation script for Ubuntu 24.04"

    check_root

    if check_tailscale_installed; then
        log_info "tailscale is already properly installed, nothing to do"
        exit 0
    fi

    install_tailscale

    log_info "tailscale has been successfully installed"
}

main "$@"
