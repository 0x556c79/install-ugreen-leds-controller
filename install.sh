#!/bin/bash
set -e

# Ensure script is run with sudo
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root or with sudo"
    exit 1
fi

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

# Set INSTALL_DIR
INSTALL_HOME=$(eval echo ~$INSTALL_USER)
INSTALL_DIR="${INSTALL_HOME}/ugreen_leds_controller"
cd $INSTALL_HOME

# Change ownership to the original user
chown $INSTALL_USER:$INSTALL_USER "$INSTALL_DIR"

# Create a temporary file to store the installation directory
INSTALL_DIR_FILE=$(mktemp)
echo "$INSTALL_DIR" > "$INSTALL_DIR_FILE"
chmod 666 "$INSTALL_DIR_FILE"

# Download the installation script
echo "Downloading original installation script..."
curl -Ls https://raw.githubusercontent.com/0x556c79/install_ugreen_leds_controller/main/install_ugreen_leds_controller.sh -o install_ugreen_leds_controller.sh

# Make the script executable
chmod +x install_ugreen_leds_controller.sh

# Execute the installation script, passing the temp file
echo "Running UGREEN LEDs Controller installation..."
INSTALL_DIR_FILE="$INSTALL_DIR_FILE" ./install_ugreen_leds_controller.sh

# Clean up the temporary file
rm "$INSTALL_DIR_FILE"

echo "UGREEN LEDs Controller installation completed successfully!"
