#!/bin/bash

# Prompt for the password
echo "Enter password for new user noeruid:"
read -s PASSWORD

# Create the new user
sudo useradd -m -s /bin/bash noeruid

# Set the password for the new user
echo "noeruid:$PASSWORD" | sudo chpasswd

# Add the new user to the sudo group
sudo usermod -aG sudo noeruid

# Configure sudoers file to allow sudo without password for the new user
echo "noeruid ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/noeruid

echo "User noeruid has been created and configured."
