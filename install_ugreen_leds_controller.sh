#!/bin/bash

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root."
    exit 1
fi

# Variables
REPO_URL="https://raw.githubusercontent.com/miskcoo/ugreen_leds_controller/refs/heads/gh-actions/build-scripts/truenas/build"
SUPPORTED_VERSIONS=("24.10.0" "24.10.0.1" "24.10.0.2" "24.04.0" "24.04.1" "24.04.1.1" "24.04.2")
TRUENAS_VERSION=$(cat /etc/version | grep -oP '^[0-9]+\.[0-9]+(\.[0-9]+)?(\.[0-9]+)?')
TRUENAS_SERIES=$(echo "$TRUENAS_VERSION" | cut -d'.' -f1,2)

# Map version to TrueNAS name
if [[ "$TRUENAS_SERIES" == "24.10" ]]; then
    TRUENAS_NAME="TrueNAS-SCALE-ElectricEel"
elif [[ "$TRUENAS_SERIES" == "24.04" ]]; then
    TRUENAS_NAME="TrueNAS-SCALE-Dragonfish"
else
    echo "Unsupported TrueNAS SCALE version series: ${TRUENAS_SERIES}."
    echo "Please build the kernel module manually."
    exit 1
fi

# Validate full version
if [[ ! " ${SUPPORTED_VERSIONS[@]} " =~ " ${TRUENAS_VERSION} " ]]; then
    echo "Unsupported TrueNAS SCALE version: ${TRUENAS_VERSION}."
    echo "Please build the kernel module manually."
    exit 1
fi

# Construct the kernel module URL
MODULE_URL="${REPO_URL}/${TRUENAS_NAME}/${TRUENAS_VERSION}/led-ugreen.ko"

# Test if the kernel module URL is valid
echo "Checking if kernel module exists for TrueNAS version ${TRUENAS_VERSION}..."
if ! curl --head --silent --fail "${MODULE_URL}" > /dev/null; then
    echo "Kernel module not found for TrueNAS version ${TRUENAS_VERSION}."
    echo "Please build the kernel module manually."
    exit 1
fi

# Variables for remount paths
BOOT_POOL_PATH="boot-pool/ROOT/${TRUENAS_VERSION}"

# Step 1: Remount boot-pool datasets with write access
echo "Remounting boot-pool datasets with write access..."
mount -o remount,rw "${BOOT_POOL_PATH}/usr" || exit 1
mount -o remount,rw "${BOOT_POOL_PATH}/etc" || exit 1

# Step 2: Clone the Ugreen LEDs Controller repository
echo "Cloning Ugreen LEDs Controller repository..."
cd /root
if [ ! -d "/root/ugreen_leds_controller" ]; then
    git clone https://github.com/miskcoo/ugreen_leds_controller.git || exit 1
fi

# Step 3: Download and install the kernel module
echo "Downloading and installing the kernel module..."
mkdir -p "/lib/modules/$(uname -r)/extra"
curl -o "/lib/modules/$(uname -r)/extra/led-ugreen.ko" "${MODULE_URL}" || exit 1
chmod 644 "/lib/modules/$(uname -r)/extra/led-ugreen.ko"

# Step 4: Create kernel module load configuration
echo "Creating kernel module load configuration..."
cat <<EOL > /etc/modules-load.d/ugreen-led.conf
i2c-dev
led-ugreen
ledtrig-oneshot
ledtrig-netdev
EOL
chmod 644 /etc/modules-load.d/ugreen-led.conf

# Step 5: Load kernel modules
echo "Loading kernel modules..."
depmod
modprobe -a i2c-dev led-ugreen ledtrig-oneshot ledtrig-netdev

# Step 6: Ask user if they want to modify the configuration file
echo "Do you want to modify the LED configuration file now? (y/n)"
read -r MODIFY_CONF
if [[ "$MODIFY_CONF" == "y" ]]; then
    nano /root/ugreen_leds_controller/scripts/ugreen-leds.conf
fi

# Copy the configuration file
cp /root/ugreen_leds_controller/scripts/ugreen-leds.conf /etc/ugreen-leds.conf
chmod 644 /etc/ugreen-leds.conf

# Step 7: Detect active network interfaces and configure services
echo "Detecting network interfaces..."
NETWORK_INTERFACES=($(ifconfig | grep -oP 'enp[0-9]+[a-z][0-9]+'))

if [ ${#NETWORK_INTERFACES[@]} -eq 0 ]; then
    echo "Warning: No network interfaces detected. Skipping ugreen-netdevmon service setup."
else
    # Check which interfaces are active
    ACTIVE_INTERFACES=()
    for interface in "${NETWORK_INTERFACES[@]}"; do
        if ifconfig "$interface" | grep -q "UP"; then
            ACTIVE_INTERFACES+=("$interface")
        fi
    done

    if [ ${#ACTIVE_INTERFACES[@]} -eq 0 ]; then
        echo "No active interfaces detected. Skipping ugreen-netdevmon service setup."
        exit 0
    elif [ ${#ACTIVE_INTERFACES[@]} -eq 1 ]; then
        CHOSEN_INTERFACE="${ACTIVE_INTERFACES[0]}"
        echo "Detected one active interface: ${CHOSEN_INTERFACE}."
    else
        echo "Multiple active interfaces detected: ${ACTIVE_INTERFACES[*]}"
        echo "Please choose one interface to use:"
        select CHOSEN_INTERFACE in "${ACTIVE_INTERFACES[@]}"; do
            if [[ -n "$CHOSEN_INTERFACE" ]]; then
                echo "You selected: ${CHOSEN_INTERFACE}"
                break
            else
                echo "Invalid selection. Please try again."
            fi
        done
    fi
fi

# Step 8: Copy scripts and configure services
echo "Setting up systemd services..."
cd /root/ugreen_leds_controller

scripts=("ugreen-diskiomon" "ugreen-netdevmon" "ugreen-probe-leds")
for script in "${scripts[@]}"; do
    chmod +x "scripts/$script"
    cp "scripts/$script" /usr/bin
done

cp scripts/*.service /etc/systemd/system/
systemctl daemon-reload

# Enable and start diskiomon service
echo "Enabling and starting ugreen-diskiomon service..."
systemctl start ugreen-diskiomon.service
systemctl enable ugreen-diskiomon.service

# Enable and start netdevmon services for all detected interfaces
if [ ${#NETWORK_INTERFACES[@]} -eq 0 ]; then
    echo "Warning: No network interfaces detected. Skipping ugreen-netdevmon service setup."
else
    echo "Enabling and starting ugreen-netdevmon service for interface: ${CHOSEN_INTERFACE}..."
    systemctl start "ugreen-netdevmon@${CHOSEN_INTERFACE}"
    systemctl enable "ugreen-netdevmon@${CHOSEN_INTERFACE}"
fi

echo "Setup complete. Reboot your system to verify."