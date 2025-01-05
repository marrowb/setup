#!/usr/bin/env bash

# Ensure NVM is loaded
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Check if npm is available
if ! command -v npm &> /dev/null; then
    echo "npm is not installed or not in PATH. Please ensure Node.js and npm are properly installed."
    exit 1
fi

# Install Bitwarden CLI
npm install -g @bitwarden/cli

# Verify installation
if command -v bw &> /dev/null; then
    echo "Bitwarden CLI installed successfully"
    bw --version
else
    echo "Bitwarden CLI installation failed"
    exit 1
fi
