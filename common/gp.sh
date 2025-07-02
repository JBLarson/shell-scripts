#!/bin/sh

# gp.sh - conditional git push utility

# Check for commit message
if [ -z "$1" ]; then
	echo "Usage: gp.sh \"Your commit message\""
	exit 1
fi

# Run git commands
git add .
git commit -m "$1"
git pull --rebase

# Get the absolute path
CURRENT_DIR=$(pwd)

# Conditional push
if [ "$CURRENT_DIR" = "$HOME/Documents/github/coprospects" ]; then
	git push origin staging && git push tiki staging
else
	git push origin main
fi
