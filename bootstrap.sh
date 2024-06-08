#!/bin/bash

# URL of the script in the GitHub repository
SCRIPT_URL="https://raw.githubusercontent.com/gustileo/auto-install-scripts/main/install_remote_desktop.sh"

# Download the script
curl -O $SCRIPT_URL

# Make the script executable
chmod +x install_remote_desktop.sh

# Execute the script
./install_remote_desktop.sh
