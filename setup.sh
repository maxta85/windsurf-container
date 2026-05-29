#!/bin/bash

# Verify SSH key setup for ai@myserver
if ! ssh -o StrictHostKeyChecking=no ai@myserver 'echo OK'; then
  echo "SSH key not set up or server unreachable. Please configure SSH key for ai@myserver."
  exit 1
fi

# Copy files to server
echo "Copying files to server..."
scp -r ./* ai@myserver:/home/ai/windsurf-container

# SSH to server and execute deployment
ssh ai@myserver <<'ENDSSH'
  # Navigate to project directory
  cd /home/ai/windsurf-container

  # Build image and start container
  echo "Building Docker image..."
  docker compose build

  echo "Starting container..."
  docker compose up -d

  # Validate container
  if ! docker ps | grep -q windsurf-dev; then
    echo "Container failed to start. Check docker-compose output for errors."
    exit 1
  fi

  # Guide through Tailscale auth unless already set
  if ! docker exec windsurf-dev tailscale status | grep -q 'authenticated'; then
    echo "Opening terminal for Tailscale authentication..."
    echo "Please authenticate with your Tailscale account when prompted."
    docker exec -it windsurf-dev tailscale up
    echo "Tailscale authentication completed. Connection ready."
  fi

  echo "Setup complete!"
ENDSSH

# Cleanup temporary files
rm -rf .ssh *env *.log 
tail -f /dev/null > /dev/null