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

install_ebpf_tools() {
    log_info "Updating package database"
    apt update

    log_info "Installing ebpf_tools packages"
    apt install -y bpfcc-tools "linux-headers-$(uname -r)"

    log_info "ebpf_tools installation completed successfully"
}

main() {
    log_info "Starting ebpf_tools installation script for Ubuntu 24.04"

    check_root

    install_ebpf_tools

    log_info "ebpf_tools has been successfully installed"
}

main "$@"
