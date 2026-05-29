FROM ubuntu:22.04

# Set non-interactive mode for apt
ENV DEBIAN_FRONTEND=noninteractive

# Install essential packages
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    vim \
    nano \
    htop \
    net-tools \
    nmap \
    iputils-ping \
    openssh-client \
    openssh-server \
    sudo \
    build-essential \
    python3 \
    python3-pip \
    nodejs \
    npm \
    docker.io \
    && rm -rf /var/lib/apt/lists/*

# Install Tailscale
RUN curl -fsSL https://tailscale.com/install.sh | sh

# Install Windsurf IDE server
# Note: The exact installation method for Windsurf may vary.
# This example assumes a Debian package is available from Windsurf's repository.
# Replace with actual installation method as needed.
RUN echo "Installing Windsurf IDE server..." && \
    # Example: Add Windsurf repository and install
    # Replace the following lines with actual Windsurf installation instructions
    mkdir -p /tmp/windsurf-install && \
    mkdir -p /opt/windsurf && \
    cd /tmp/windsurf-install && \
    # Download Windsurf (example URL - replace with actual)
    # wget https://windsurf.sh/install.sh && \
    # chmod +x install.sh && \
    # ./install.sh
    # For now, we'll create a placeholder
    echo "Windsurf installation placeholder - replace with actual installation" > /opt/windsurf/README.md && \
    ln -s /opt/windsurf/README.md /usr/local/bin/windsurf && \
    chmod +x /usr/local/bin/windsurf && \
    rm -rf /tmp/windsurf-install

# Create coder user with sudo NOPASSWD
RUN useradd -m -s /bin/bash coder && \
    echo 'coder ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/coder && \
    chmod 0440 /etc/sudoers.d/coder

# Set up SSH server
RUN mkdir -p /var/run/sshd && \
    sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config && \
    sed -i 's/#ListenAddress 0.0.0.0/ListenAddress 0.0.0.0/' /etc/ssh/sshd_config && \
    sed -i 's/#ListenAddress ::0/ListenAddress ::/' /etc/ssh/sshd_config && \
    echo 'PermitRootLogin no' >> /etc/ssh/sshd_config && \
    echo 'PasswordAuthentication no' >> /etc/ssh/sshd_config && \
    echo 'PubkeyAuthentication yes' >> /etc/ssh/sshd_config && \
    echo 'AuthorizedKeysFile .ssh/authorized_keys' >> /etc/ssh/sshd_config && \
    echo 'AllowUsers coder' >> /etc/ssh/sshd_config

# Create directory for SSH keys for coder user
RUN mkdir -p /home/coder/.ssh && \
    chown -R coder:coder /home/coder/.ssh && \
    chmod 700 /home/coder/.ssh

# Expose SSH port (will be mapped to host via docker-compose)
EXPOSE 2222

# Set working directory
WORKDIR /home/coder

# Copy SSH public key if provided (for initial setup)
# This will be overridden by setup.sh or user's own keys
# COPY --chown=coder:coder id_rsa.pub /home/coder/.ssh/authorized_keys

# Entrypoint script to start SSH and Tailscale
# Run as root to start system services, coder user will be used for SSH login
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]