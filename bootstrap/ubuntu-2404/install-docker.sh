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

check_docker_installed() {
    if command -v docker >/dev/null 2>&1 && getent group docker | grep -q "\b${SUDO_USER:-$USER}\b"; then
        log_info "Docker is already installed and user is in the docker group"
        return 0
    fi
    return 1
}

install_docker() {
    log_info "Creating Docker keyring directory"
    mkdir -p /etc/apt/keyrings

    log_info "Downloading Docker GPG key"
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc

    log_info "Adding Docker repository"

    # shellcheck source=/dev/null
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$UBUNTU_CODENAME") stable" | \
        tee /etc/apt/sources.list.d/docker.list > /dev/null

    log_info "Updating package database"
    apt update

    log_info "Installing Docker packages"
    apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    log_info "Starting and enabling Docker service"
    systemctl start docker
    systemctl enable docker

    # Add the current user to the docker group if we're running with sudo
    if [[ -n "${SUDO_USER:-}" ]]; then
        log_info "Adding user $SUDO_USER to the docker group"
        usermod -aG docker "$SUDO_USER"
        log_info "Note: The user will need to log out and back in for group changes to take effect"
    else
        log_warn "Could not determine non-root user to add to docker group"
        log_warn "Remember to add your user to the docker group with: usermod -aG docker <username>"
    fi

    log_info "Docker installation completed successfully"
}

main() {
    log_info "Starting Docker installation script for Ubuntu 24.04"

    check_root

    if check_docker_installed; then
        log_info "Docker is already properly installed, nothing to do"
        exit 0
    fi

    install_docker

    log_info "Docker has been successfully installed"
}

main "$@"
