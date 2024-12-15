#!/bin/bash
set -e

# UGREEN LEDs Controller Installer
echo "Installing UGREEN LEDs Controller..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root. Use sudo."
    exit 1
fi

# Determine the user who invoked sudo (or the current user if root)
if [ -n "$SUDO_USER" ]; then
    INSTALL_USER=$SUDO_USER
elif [ -n "$USER" ]; then
    INSTALL_USER=$USER
else
    INSTALL_USER=$(id -un)
fi

# Use INSTALL_DIR if set, otherwise create a default
if [ -z "$INSTALL_DIR" ]; then
    INSTALL_HOME=$(eval echo ~$INSTALL_USER)
    INSTALL_DIR="${INSTALL_HOME}/ugreen-leds-controller"
fi

# Create installation directory
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Change ownership to the original user
chown $INSTALL_USER:$INSTALL_USER "$INSTALL_DIR"

# Download the installation script
echo "Downloading original installation script..."
curl -L https://raw.githubusercontent.com/0x556c79/install-ugreen-leds-controller/main/install_ugreen_leds_controller.sh -o install_ugreen_leds_controller.sh

# Make the script executable
chmod +x install_ugreen_leds_controller.sh

# Execute the installation script
echo "Running UGREEN LEDs Controller installation..."
sudo -u $INSTALL_USER ./install_ugreen_leds_controller.sh

echo "UGREEN LEDs Controller installation completed successfully!"
echo "Installed in: $INSTALL_DIR"
