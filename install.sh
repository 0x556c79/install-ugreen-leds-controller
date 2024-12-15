#!/bin/bash
set -e

# UGREEN LEDs Controller Installer
echo "Installing UGREEN LEDs Controller..."

# Determine the user who invoked sudo
if [ -n "$SUDO_USER" ]; then
    INSTALL_USER=$SUDO_USER
elif [ -n "$USER" ]; then
    INSTALL_USER=$USER
else
    INSTALL_USER=$(id -un)
fi

INSTALL_HOME=$(eval echo ~$INSTALL_USER)
INSTALL_DIR="${INSTALL_HOME}/ugreen_leds_controller"

# Ensure script is run with sudo
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root or with sudo"
    exit 1
fi

# Create installation directory
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Change ownership to the original user
chown $INSTALL_USER:$INSTALL_USER "$INSTALL_DIR"

# Download the installation script
echo "Downloading installation script..."
curl -L https://raw.githubusercontent.com/0x556c79/install_ugreen_leds_controller/main/install_ugreen_leds_controller.sh -o install_ugreen_leds_controller.sh

# Make the script executable
chmod +x install_ugreen_leds_controller.sh

# Execute the installation script
echo "Running UGREEN LEDs Controller installation..."
sudo -u $INSTALL_USER ./install_ugreen_leds_controller.sh

echo "UGREEN LEDs Controller installation completed successfully!"
echo "Installed in: $INSTALL_DIR"
