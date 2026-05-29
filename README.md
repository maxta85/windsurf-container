# Windsurf Development Container

A fully automated Docker deployment system for a remote Windsurf development environment on your Linux server. This setup creates a container with Windsurf IDE, Tailscale for networking, and all necessary development tools.

## Prerequisites

Before you begin, ensure you have the following installed on your local machine:

1. **Docker Desktop** (for testing locally)
2. **OpenSSH client** (for connecting to remote server)
3. **Tailscale CLI** (optional, for local testing)
4. **Git** (for version control)

## First-Time Deployment

### Step 1: Configure Environment Variables

1. Copy the environment template:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` with your Tailscale auth key:
   ```bash
   # Get your auth key from https://login.tailscale.com/admin/settings/keys
   TS_AUTHKEY=your_tailscale_auth_key_here
   ```

   Optional settings:
   ```bash
   TS_HOSTNAME=windsurf-dev  # Custom hostname for the container
   TS_EXTRA_ARGS=--advertise-exit-node  # Optional additional Tailscale arguments
   ```

### Step 2: Deploy to Server

Run the setup script to deploy to your Linux server:

```bash
./setup.sh
```

The script will:
1. Connect to your server as `ai@myserver` (requires SSH key authentication)
2. Copy all project files to the server
3. Build and deploy the Docker container
4. Guide you through Tailscale authentication
5. Validate the container is running correctly

### Step 3: Connect to the Container

Once the container is running:

1. **From your desktop Windsurf application:**
   - Use "Remote SSH" connection
   - Connect to the container's Tailscale IP address
   - Port: 22 (SSH port)
   - User: coder

2. **Alternatively, via SSH:**
   ```bash
   ssh coder@<tailscale-ip>
   ```

## Redeploy/Update

To update or redeploy the container:

1. Push your changes to the repository (if any)
2. Run the setup script again:
   ```bash
   ./setup.sh
   ```

## Troubleshooting

### Common Issues

**Container won't start:**
- Check Docker logs: `docker logs windsurf-dev`
- Verify environment variables are set correctly in `.env`
- Ensure Tailscale auth key is valid

**Tailscale connection issues:**
- Check Tailscale status: `docker exec windsurf-dev tailscale status`
- Try re-authenticating Tailscale: `docker exec windsurf-dev tailscale up --authkey=<your-key>`
- Ensure your Tailscale account allows the device type

**SSH connection refused:**
- Verify SSH is running: `docker exec windsurf-dev service ssh status`
- Check SSH port mapping: `docker port windsurf-dev`
- Ensure SSH keys are properly set up

**Development tools not working:**
- Check if tools are installed: `docker exec windsurf-dev which <tool>`
- Rebuild the container if needed: `docker-compose build`

## Security

### What is Protected

- Container runs as unprivileged user `coder`
- SSH access requires key authentication (no passwords)
- Only localhost port 2222 is exposed
- Tunnels through Tailscale for external access
- Container has limited Linux capabilities

### What is NOT Protected

- The container can SSH back to the host server (ai@myserver)
- The container can access external servers via Tailscale
- The container has sudo privileges inside itself
- Container filesystem is isolated but not encrypted

### Best Practices

- Keep your Tailscale auth key secure
- Regularly update the container base image
- Monitor container resource usage
- Use strong SSH keys

## Maintenance

### Stop the Container

```bash
docker-compose down
```

### Restart the Container

```bash
docker-compose restart
```

### Remove the Container

```bash
docker-compose down -v  # Also removes the persistent volume
```

### View Container Logs

```bash
docker logs windsurf-dev
docker logs -f windsurf-dev  # Follow logs
```

## Support

If you encounter issues not covered here:

1. Check the container logs: `docker logs windsurf-dev`
2. Verify Tailscale status: `docker exec windsurf-dev tailscale status`
3. Check SSH service: `docker exec windsurf-dev service ssh status`
4. Contact support with the output from the above commands

## License

This project is provided as-is for educational purposes.