# MinIO Auto Installation Script

This script automates the installation of MinIO server on Linux (supports Ubuntu 22.04, CentOS, AlmaLinux, Rocky, etc.). The script will set up the MinIO server, configure the necessary firewall settings, and provide access and secret keys for managing the server.

## Prerequisites

- The script must be run as `root` or with `sudo` privileges.
- Ensure that ports `9000` and `9001` are available on your server.
- This script has been tested on:
  - **Ubuntu 22.04 (Jammy)**
  - **CentOS**
  - **AlmaLinux**
  - **Rocky Linux**

## Installation Steps

1. **Clone or Download the Script**

   You can clone this repository or download the script file directly:

   ```bash
   git clone https://your-repository-link.git
   cd your-repository
