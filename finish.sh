#!/bin/bash
# windsurf-container — End of Shift
# Ensure HANDOFF.md is updated before running this.

echo "== Staging all changes =="
git add .

echo "== Enter your commit message (brief shift summary): =="
read COMMIT_MSG
git commit -m "$COMMIT_MSG"

echo "== Pushing to GitHub =="
git push

echo "== Shift closed. Repo is up to date. =="