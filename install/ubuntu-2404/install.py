#!/usr/bin/env python3
import argparse
import logging
import subprocess
import sys
from pathlib import Path
from typing import List

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="[%(levelname)s] %(message)s",
    handlers=[
        logging.StreamHandler(sys.stdout)  # Single handler for all log levels
    ],
)
logger = logging.getLogger(__name__)


def run_command(
    cmd: List[str], check: bool = True, log_output: bool = True
) -> subprocess.CompletedProcess:
    """Run a shell command and return the result.

    Args:
        cmd: Command and arguments as a list of strings
        check: If True, raise CalledProcessError on non-zero exit code
        log_output: If True, log the command's stdout/stderr output
    """
    try:
        result = subprocess.run(cmd, check=check, text=True, capture_output=True)
        # Print the command's output if there is any and logging is enabled
        if log_output:
            if result.stdout:
                logger.info(result.stdout.rstrip())
            if result.stderr:
                logger.error(result.stderr.rstrip())
        return result
    except subprocess.CalledProcessError as e:
        logger.error(f"Command failed: {' '.join(cmd)}")
        logger.error(f"Error: {e.stderr}")
        if check:
            sys.exit(1)
        return e


def command_exists(cmd: str) -> bool:
    """Check if a command exists in the system."""
    try:
        run_command(["which", cmd], check=False, log_output=False)
        return True
    except subprocess.CalledProcessError:
        return False


def require_command(cmd: str) -> None:
    """Ensure a required command exists."""
    if not command_exists(cmd):
        logger.error(f"{cmd} is required but not installed")
        sys.exit(1)


def read_packages(file_path: str) -> List[str]:
    """Read package files, handling comments properly."""
    path = Path(file_path)
    if not path.exists():
        logger.error(f"Package file not found: {file_path}")
        sys.exit(1)

    packages = []
    with open(path) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith("#"):
                # Remove inline comments
                package = line.split("#")[0].strip()
                if package:
                    packages.append(package)
    return packages


def install_apt_packages() -> None:
    """Install apt packages."""
    script_dir = Path(__file__).parent
    apt_file = script_dir / "apt.txt"

    logger.info("Starting system package installation...")
    logger.info("Updating apt package lists to ensure latest versions...")
    run_command(["sudo", "apt", "update"])

    packages = read_packages(str(apt_file))
    if packages:
        logger.info(f"Installing {len(packages)} system packages via apt:")
        run_command(["sudo", "apt", "install", "-y"] + packages)
    else:
        logger.warning("No apt packages found to install")


def install_homebrew() -> None:
    """Install Homebrew packages."""
    script_dir = Path(__file__).parent
    brew_file = script_dir / "brew.txt"

    logger.info("Starting Homebrew package installation...")
    packages = read_packages(str(brew_file))
    if packages:
        logger.info(f"Installing {len(packages)} packages via Homebrew:")
        for package in packages:
            run_command(["brew", "install", package])
    else:
        logger.warning("No Homebrew packages found to install")


def install_rust() -> None:
    """Install Rust toolchain."""
    if not command_exists("rustup"):
        logger.error("Rustup not found. Please install Rust toolchain first.")
        sys.exit(1)

    logger.info("Starting Rust toolchain installation...")
    run_command(["rustup", "toolchain", "install", "stable"])
    logger.info("Rust toolchain installation complete")


def install_python() -> None:
    """Install Python versions using uv."""
    script_dir = Path(__file__).parent
    python_file = script_dir / "uv-python.txt"

    logger.info("Starting Python version installation via uv...")
    versions = read_packages(str(python_file))
    if versions:
        logger.info(f"Installing {len(versions)} Python versions:")
        for version in versions:
            run_command(["uv", "python", "install", version])
    else:
        logger.warning("No Python versions found to install")


def install_python_tools() -> None:
    """Install Python tools using uv."""
    script_dir = Path(__file__).parent
    tools_file = script_dir / "uv-tool.txt"

    logger.info("Starting Python tool installation via uv...")
    tools = read_packages(str(tools_file))
    if tools:
        logger.info(f"Installing {len(tools)} Python tools:")
        for tool in tools:
            run_command(["uv", "tool", "install", tool])
    else:
        logger.warning("No Python tools found to install")


def install_npx() -> None:
    """Install NPX packages."""
    script_dir = Path(__file__).parent
    npx_file = script_dir / "npx.txt"

    logger.info("Starting global NPX package installation...")
    packages = read_packages(str(npx_file))
    if packages:
        logger.info(f"Installing {len(packages)} global NPX packages:")
        for package in packages:
            logger.info(f"  - {package}")
            run_command(["npm", "install", "-g", package])
    else:
        logger.warning("No NPX packages found to install")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Set up a development environment on Ubuntu 24.04",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
This script sets up a development environment on Ubuntu 24.04 by installing:
- System packages (apt)
- Homebrew packages
- Rust toolchain
- Python versions and tools via uv
- NPX packages
        """,
    )
    parser.parse_args()

    logger.info("Starting Ubuntu 24.04 development environment setup...")

    # Check required commands
    logger.info("Checking required system commands...")
    require_command("curl")
    require_command("sudo")
    require_command("brew")
    logger.info("All required commands are available")

    # Run installations
    logger.info("Beginning package installations...")
    install_apt_packages()
    install_homebrew()
    install_rust()
    install_python()
    install_python_tools()
    install_npx()

    logger.info(
        "Development environment setup complete! All packages have been installed successfully."
    )


if __name__ == "__main__":
    main()
