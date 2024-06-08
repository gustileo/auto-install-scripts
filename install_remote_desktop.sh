#!/bin/bash

# Step 1: Install Google Remote Desktop
# Add the Google signing key
curl https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/chrome-remote-desktop.gpg

# Add the Chrome Remote Desktop repository
echo "deb [arch=amd64] https://dl.google.com/linux/chrome-remote-desktop/deb stable main" | sudo tee /etc/apt/sources.list.d/chrome-remote-desktop.list

# Update package lists
sudo apt-get update

# Install Chrome Remote Desktop
sudo DEBIAN_FRONTEND=noninteractive apt-get install --assume-yes chrome-remote-desktop

# Step 2: Install XFCE and related packages
sudo DEBIAN_FRONTEND=noninteractive apt install --assume-yes xfce4 desktop-base dbus-x11 xscreensaver

# Step 3: Disable LightDM service
sudo systemctl disable lightdm.service

# Step 4: Install Google Chrome
curl -L -o google-chrome-stable_current_amd64.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt install --assume-yes --fix-broken ./google-chrome-stable_current_amd64.deb

# Cleanup
rm google-chrome-stable_current_amd64.deb

# Step 5: Download and execute setup.sh for additional software installation
curl -O https://raw.githubusercontent.com/noeruid/auto-install-scripts/main/setup.sh
chmod +x setup.sh
./setup.sh

echo "Installation of Google Remote Desktop, XFCE, and additional software is complete."
