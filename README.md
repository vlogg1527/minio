# MinIO Auto Installation Script

This script automates the installation of the MinIO server on Linux-based systems (supports Ubuntu 22.04, CentOS, AlmaLinux, Rocky, and more). The script will set up the MinIO server, configure the necessary firewall settings, and generate access and secret keys for managing the server.

## Prerequisites

- **Root Access**: The script must be run as the `root` user or with `sudo` privileges.
- **Ports Availability**: Ensure that ports `9000` and `9001` are available for MinIO server and console access.
- **Tested on**:
  - **Ubuntu 22.04 (Jammy)**
  - **CentOS**
  - **AlmaLinux**
  - **Rocky Linux**

## Features

- Automates the entire process of downloading and installing the MinIO server.
- Configures ports `9000` and `9001` automatically using either `ufw` or `firewalld`, depending on the OS.
- Automatically sets up a systemd service for managing MinIO as a system service.
- Generates random Access and Secret keys for securing the MinIO server.
- Provides easy access to the MinIO web console and storage server upon completion.

## Installation Steps

### Step 1: Clone or Download the Script

You can either clone this repository using Git or download the script manually:

#### Clone the repository using Git:

```bash
git clone https://github.com/vlogg1527/minio.git
cd minio


Step 2: Make the Script Executable

chmod +x install.sh


sudo ./install.sh /path/to/minio/storage



========================================================
MinIO server installed successfully! Storage path: /data/minio
--------------------------------------------------------
Synchronization config:
endPoint: 192.168.1.100
Port: 9000
Access Key: abcdef1234
Secret Key: abcdef5678
--------------------------------------------------------
Web console info:
URL: http://192.168.1.100:9001
Username: abcdef1234
Password: abcdef5678
--------------------------------------------------------
Please save this information.
========================================================
