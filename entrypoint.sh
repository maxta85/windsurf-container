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

# Keep container running
echo "Container is ready. SSH available on port 2222."
echo "To stop the container, press Ctrl+C or run 'docker stop <container>'."

# Wait indefinitely
while true; do
    sleep 60
done