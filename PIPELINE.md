# windsurf-container

## What This Project Is
A fully automated Docker deployment system that creates a remote Windsurf development environment on a Linux server. The container includes Windsurf IDE, Tailscale for secure networking, and all essential development tools, allowing AI agents to work autonomously via Windsurf Remote SSH.

## Goals
- Provide a one-command deployment script for non-technical users
- Create a secure, isolated development container with full root access inside the container
- Enable AI agents to complete entire projects without human intervention
- Ensure security by running as unprivileged user with limited capabilities
- Integrate Tailscale for seamless remote access without exposing ports to the internet
- Persist project files via Docker volumes
- Automatically start SSH and Tailscale services on container boot

## Architecture
- Docker container based on Ubuntu 22.04
- Internal services: SSH server (port 2222), Tailscale daemon
- User: "coder" with passwordless sudo privileges
- Persistent storage: Docker volume mounted at /home/coder/projects
- Security: drops all Linux capabilities except essential ones, no-new-privileges, no host mounts
- Entrypoint: starts SSH and Tailscale, then keeps container running

## Conventions
- All deployment scripts use Bash with strict error handling (set -e)
- Environment variables stored in .env file (gitignored)
- SSH key authentication only - no passwords
- Container name: windsurf-dev
- Internal SSH port: 2222 (mapped to localhost only on host)
- Tailscale hostname defaults to windsurf-dev
- Project files stored in /home/coder/projects inside container
- Agent must run start.sh before beginning work and finish.sh at end
- Never commit .env file or sensitive credentials
- Never push directly to GitHub - always use finish.sh

## Commands

These are text conventions using // to avoid conflicts with built-in IDE
and agent slash commands. Any agent on any platform will recognise and
honour them. Use them at any point during a shift.

//pull     — Pull the latest files from GitHub
//push     — Commit and push all files to GitHub main
//review   — Review the codebase, understand how it works, give a brief summary
//debug    — Sweep the project for bugs, report findings before fixing anything
//finish   — Run finish.sh — update HANDOFF.md first, then close the shift
//pipe     — Read PIPELINE.md and summarise current conventions and rules
//soso     — Re-run Start of Shift Orientation if context has drifted
//status   — Summarise current state: what's done, what's in progress, what's next

Agents must not take destructive action from any command without human approval.
//debug reports findings only — it does not auto-fix.
//push and //finish both require HANDOFF.md to be current before executing.

## Off Limits
- Never push directly to GitHub from an agent session — always use finish.sh
- Never rewrite or delete PIPELINE.md; append only when fundamental changes occur
- Never commit secrets, keys, or .env file to repository
- Never change the container user from "coder" without updating all related files
- Never mount host filesystem or Docker socket into the container
- Never run container in privileged mode or with --privileged flag
- Never expose SSH port to public internet - only localhost binding allowed