#!/bin/bash
set -e

# Start SSH service
echo "Starting SSH service..."
service ssh start

# Start Tailscale
echo "Starting Tailscale..."
# Start tailscaled daemon in background
tailscaled --state=/tmp/tailscaled.state --socket=/tmp/tailscaled.sock &
sleep 2

# If auth key is provided via environment variable, login
if [ -n "$TS_AUTHKEY" ]; then
    echo "Authenticating with Tailscale using provided auth key..."
    tailscale --socket=/tmp/tailscaled.sock up --authkey="$TS_AUTHKEY" --hostname=${TS_HOSTNAME:-windsurf-dev} ${TS_EXTRA_ARGS:-}
else
    echo "TS_AUTHKEY not set. Please ensure Tailscale is configured via other means or set TS_AUTHKEY."
    # Try to start without auth (if already authenticated)
    tailscale --socket=/tmp/tailscaled.sock up --hostname=${TS_HOSTNAME:-windsurf-dev} ${TS_EXTRA_ARGS:-} || true
fi

# Show Tailscale IP
echo "Tailscale status:"
tailscale --socket=/tmp/tailscaled.sock status || echo "Tailscale not fully started yet"

# Start headless Windsurf if WINDSURF_TOKEN is provided
if [ -n "$WINDSURF_TOKEN" ]; then
    echo "WINDSURF_TOKEN set. Starting headless Windsurf agent..."
    echo "Instructions file: /home/coder/workspace/windsurf-instructions.txt"
    echo "Output file: /home/coder/workspace/windsurf-output.txt"
    sudo -u coder WINDSURF_TOKEN="$WINDSURF_TOKEN" /usr/local/bin/windsurf-headless.sh
else
    echo "WINDSURF_TOKEN not set. Headless Windsurf agent not started."
    echo "To start headless Windsurf agent manually:"
    echo "  1. Create /home/coder/workspace/windsurf-instructions.txt with your instructions"
    echo "  2. Set WINDSURF_TOKEN environment variable"
    echo "  3. Run: sudo -u coder WINDSURF_TOKEN=\$WINDSURF_TOKEN /usr/local/bin/windsurf-headless.sh"
fi

# Keep container running
echo "Container ready. Services running:"
echo "  - SSH on port 2222"
echo "  - Tailscale VPN"

# Wait indefinitely
while true; do
    sleep 60
done