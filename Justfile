# Default recipe to display help
default:
    @just --list

bootstrap-creds host:
    @echo "Syncing credentials to {{host}}"

# Rsync this repository to a target host
bootstrap-rsync host path:
    @echo "Syncing repository to {{host}}:{{path}}"
    rsync -avzP \
        --exclude-from='.gitignore' \
        --exclude='*.log' \
        --filter=':- .gitignore' \
        --delete \
        ./ {{host}}:{{path}}/

# Rsync with dry-run to preview what would be synced
bootstrap-rsync-dry host path:
    @echo "Dry run: Syncing repository to {{host}}:{{path}}"
    rsync -avzPn \
        --exclude-from='.gitignore' \
        --exclude='.git/' \
        --exclude='*.log' \
        --filter=':- .gitignore' \
        --delete \
        ./ {{host}}:{{path}}/

install-packages:
  @echo "Install packages"

symlink-config:
  @echo "Symlink config"

test-integration-build:
  @echo "Testing building docker image"
  docker build -t workbench-test-build -f contrib/docker/full/Dockerfile .
  @echo "Build completed successfully!"

test-integration-install:
  @echo "Building and testing install script in Docker..."
  docker build -t workbench-test-install -f tests/integration/install/ubuntu-2404/Dockerfile.test .
  docker run -t workbench-test-install
  @echo "Install test completed successfully!"

test-integration-dotfiles:
  @echo "Building and testing dotfiles in Docker..."
  docker build -t workbench-test-dotfiles -f tests/integration/dotfiles/Dockerfile.test .
  docker run -t workbench-test-dotfiles
  @echo "Dotfiles test completed successfully!"

# Test the packages script and dotfiles in Docker containers
test-integration: test-integration-build test-integration-install test-integration-dotfiles

# Run all pre-commit checks
lint:
    @echo "Running pre-commit checks..."
    pre-commit run --all-files
