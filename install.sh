#!/bin/bash

# Check if the correct number of arguments is provided
[[ "$#" -ne 1 ]] && echo -e "Invalid number of arguments. Please rerun the script with a directory path.\033[0m" && exit 1;

# Validate the folder format
[[ $(echo "${1}" | grep -c '^/') -eq 0 || $(echo "${1}" | grep -c '/$') -ne 0 ]] && echo -e "Invalid directory format. Please rerun the script with the correct format.\033[0m" && exit 1;

# Create the directory if it does not exist
[[ ! -d "${1}" ]] && mkdir -p "${1}";

# Ensure the script is run as root
[[ $(id -u) -ne 0 ]] && echo -e "You are not running the script as root. Please switch to root and try again.\033[0m" && exit 1;

# Detect OS
source /etc/os-release

# Check if MinIO is already installed
if command -v minio >/dev/null 2>&1; then
    echo -e "MinIO server is already installed. Exiting the installation!\033[0m"
    exit 1
fi

# Install net-tools if not present
if ! command -v netstat >/dev/null 2>&1; then
    if [[ "$ID" == "centos" || "$ID" == "almalinux" || "$ID" == "rocky" ]]; then
        yum install net-tools -y >/dev/null 2>&1
    else
        apt install net-tools -y >/dev/null 2>&1
    fi
fi

# Disable SELinux if enforcing (only applies to CentOS/AlmaLinux/Rocky)
if command -v sestatus >/dev/null 2>&1; then
    if [[ "$(getenforce)" == "Enforcing" ]]; then
        sed -i 's#SELINUX=enforcing#SELINUX=disabled#g' /etc/selinux/config
        setenforce 0
    fi
fi

# Check if the required ports (9000, 9001) are available
if [[ $(netstat -tlpn | grep -w 9000 | wc -l) -ne 0 ]]; then
    echo -e "Port 9000 is already in use. Exiting the installation!\033[0m"
    exit 1
fi

if [[ $(netstat -tlpn | grep -w 9001 | wc -l) -ne 0 ]]; then
    echo -e "Port 9001 is already in use. Exiting the installation!\033[0m"
    exit 1
fi

# Download MinIO binary
wget https://dl.min.io/server/minio/release/linux-amd64/minio -P /usr/local/bin/

# Make it executable
chmod +x /usr/local/bin/minio

# Ensure MinIO was installed
if ! command -v minio >/dev/null 2>&1; then
    echo -e "Failed to install MinIO server. Please try the installation again!\033[0m"
    exit 1
fi

# Generate random access and secret keys
AccessKey="$(head /dev/urandom | cksum | md5sum | cut -c 1-10)"
SecretKey="$(head /dev/urandom | cksum | md5sum | cut -c 1-10)"

# Create the MinIO systemd service file
cat > /etc/systemd/system/minios.service <<EOF
[Unit]
Description=MinIO server
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/minio server "${1}" --console-address ":9001"
Environment=MINIO_ROOT_USER=${AccessKey} MINIO_ROOT_PASSWORD=${SecretKey}
PIDFile=/var/run/minio.pid
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

# Start and enable MinIO service
systemctl start minios
systemctl enable minios

# Configure the firewall based on the OS
if [[ "$ID" == "centos" || "$ID" == "almalinux" || "$ID" == "rocky" ]]; then
    firewall-cmd --zone=public --add-port=9000/tcp --permanent
    firewall-cmd --zone=public --add-port=9001/tcp --permanent
    firewall-cmd --reload
else
    ufw allow 9000
    ufw allow 9001
fi

# Set timezone to Asia/Shanghai if available
timezone_file="/usr/share/zoneinfo/Asia/Shanghai"
if [ -f "$timezone_file" ]; then
    current_link=$(readlink /etc/localtime)
    if [ "$current_link" != "$timezone_file" ]; then
        rm -rf /etc/localtime
        ln -s "$timezone_file" /etc/localtime
    fi
fi

# Get the current host IP
HOSTIP=$(ip -o route get to 8.8.8.8 | sed -n 's/.*src \([0-9.]\+\).*/\1/p')

# Display the installation summary
echo "========================================================"
echo -e "MinIO server installed successfully! Storage path: ${1}"
echo "--------------------------------------------------------"
echo "Synchronization config:"
echo -e "endPoint: ${HOSTIP}"
echo -e "Port: 9000"
echo -e "Access Key: ${AccessKey}"
echo -e "Secret Key: ${SecretKey}"
echo "--------------------------------------------------------"
echo "Web console info:"
echo -e "URL: http://${HOSTIP}:9001"
echo -e "Username: ${AccessKey}"
echo -e "Password: ${SecretKey}"
echo "--------------------------------------------------------"
echo -e "Please save this information."
echo "========================================================"
