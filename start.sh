#!/bin/bash
# windsurf-container — Start of Shift
# Run this in terminal before starting your agent session.

echo "== Pulling latest from GitHub =="
git pull

# == Dependencies ==
# Added by agents each shift as new dependencies are introduced.
# Do not remove previous entries.

echo "== Loading project context =="
cat PIPELINE.md
cat HANDOFF.md

echo "== Environment ready. Paste PIPELINE.md and HANDOFF.md into your agent. =="