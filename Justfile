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

# Test the packages script in a Docker container
test-integration:
    @echo "Building and testing packages script in Docker..."
    docker build -t workbench-test -f Dockerfile.test .
    docker run -it workbench-test
    @echo "Test completed successfully!"
