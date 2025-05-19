FROM ubuntu:24.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Remove default user
RUN userdel -r ubuntu

RUN apt update
RUN apt install -y sudo

# Install sudo and create `mattjmcnaughton` user
RUN useradd -m -u 1000 -s /bin/bash mattjmcnaughton && \
    echo "mattjmcnaughton ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/mattjmcnaughton && \
    chmod 0440 /etc/sudoers.d/mattjmcnaughton

RUN apt install -y build-essential curl git wget

COPY install/ubuntu-2404 /workbench/install/ubuntu-2404
COPY dotfiles /workbench/dotfiles

RUN chown -R mattjmcnaughton:mattjmcnaughton /workbench

RUN chmod +x /workbench/install/ubuntu-2404/install.py
RUN chmod +x /workbench/dotfiles/symlink_manager.py

USER mattjmcnaughton
WORKDIR /workbench

# Install Homebrew
RUN wget https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh && \
    chmod +x install.sh && \
    bash install.sh && \
    rm install.sh
ENV PATH=~/.local/bin:/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN brew install python3
RUN ./dotfiles/symlink_manager.py --all --exclude nvim-no-plugins
RUN ./install/ubuntu-2404/install.py
RUN nvim --headless "+Lazy! sync" +qa
