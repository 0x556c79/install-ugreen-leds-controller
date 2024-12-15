## Ugreen LED Controller Installer

This repository contains a bash script to install the necessary software for controlling Ugreen LED controllers.

## Quick Installation

Run the following command with sudo or as root to install:

```bash
bash <(curl -s https://raw.githubusercontent.com/0x556c79/install_ugreen_leds_controller/main/install_ugreen_leds_controller.sh)
```
**What This Installer Does:**

- Clones the [ugreen_leds_controller](https://github.com/miskcoo/ugreen_leds_controller) repository
- Copies the files to the required locations and loads the kernel modules
- Starts the service

**Security Considerations:**
- Always validate what the script does before running
- Recommend users review the script before executing


## Manual Installation

There are two ways to use this script:

**1. Clone the repository:**

```bash
git clone https://github.com/0x556c79/install_ugreen_leds_controller.git
cd install-ugreen-leds-controller
```

**2. Copy the script:**

* Visit the raw script URL: [https://raw.githubusercontent.com/.../install_ugreen_leds_controller.sh](https://raw.githubusercontent.com/0x556c79/install_ugreen_leds_controller/refs/heads/main/install_ugreen_leds_controller.sh)
* Copy the entire script content.
* Paste the content into a new file named `install_ugreen_leds_controller.sh`.
* Or use curl
```bash
  curl https://raw.githubusercontent.com/0x556c79/install_ugreen_leds_controller/refs/heads/main/install_ugreen_leds_controller.sh -o install_ugreen_leds_controller.sh
```

**Make the script executable:**

```bash
chmod +x install_ugreen_leds_controller.sh
```

**Run the script:**

```bash
./install_ugreen_leds_controller.sh
```

**Note:** This script might require administrative privileges (sudo) depending on your system configuration. 

This script will download and install the necessary software from [https://github.com/miskcoo/ugreen_leds_controller](https://github.com/miskcoo/ugreen_leds_controller) to control your Ugreen LED controller.

**Disclaimer:** 

Createt and tested on a Ugreen DXP8800 Plus NAS.
Use this script at your own risk. The author is not responsible for any damage caused by running this script.
