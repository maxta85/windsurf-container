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

# Install X11 dependencies for headless Windsurf
RUN apt-get update && apt-get install -y \
    xvfb \
    xdotool \
    imagemagick \
    x11-apps \
    i3 \
    && rm -rf /var/lib/apt/lists/*

# Install Tailscale
RUN curl -fsSL https://tailscale.com/install.sh | sh

# Install Windsurf IDE
RUN curl -fsSL "https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/windsurf.gpg" | \
    gpg --dearmor -o /usr/share/keyrings/windsurf-stable-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/windsurf-stable-archive-keyring.gpg arch=amd64] \
    https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/apt stable main" | \
    tee /etc/apt/sources.list.d/windsurf.list > /dev/null
RUN apt-get update
RUN apt-get install -y windsurf

# Create coder user with sudo NOPASSWD
RUN useradd -m -s /bin/bash coder && \
    echo 'coder ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/coder && \
    chmod 0440 /etc/sudoers.d/coder

# Set up workspace for headless Windsurf
RUN mkdir -p /home/coder/workspace && \
    chmod ugo+rwx -R /home/coder/workspace && \
    chown coder:coder -R /home/coder/workspace

# Set up Windsurf config directory
RUN mkdir -p /home/coder/.config/i3 && \
    chown coder:coder -R /home/coder/.config

# Copy windsurfinabox resources
COPY --chown=coder:coder src/workflows/entry-workflow.md /home/coder/entry-workflow.md
COPY --chown=coder:coder src/config/i3.conf /home/coder/.config/i3/config

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

# Install Vibe-OS Express server
COPY package.json /home/coder/package.json
COPY server.js /home/coder/server.js
RUN cd /home/coder && npm install --omit=dev && chown -R coder:coder /home/coder/node_modules /home/coder/package-lock.json

# Expose web server port
EXPOSE 3000

# Entrypoint script to start SSH and Tailscale
# Run as root to start system services, coder user will be used for SSH login
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Copy windsurfinabox entrypoint for headless Windsurf
COPY src/scripts/entrypoint.sh /usr/local/bin/windsurf-headless.sh
RUN chmod +x /usr/local/bin/windsurf-headless.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]