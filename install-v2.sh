#!/bin/bash

# ฟังก์ชันสำหรับการตรวจสอบ OS
check_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    else
        OS=$(uname -s)
    fi
    echo "Detected OS: $OS"
}

# ฟังก์ชันสำหรับการติดตั้งเครื่องมือที่จำเป็น
install_prerequisites() {
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        sudo apt update
        sudo apt install -y curl wget ufw
    elif [[ "$OS" == "centos" || "$OS" == "fedora" || "$OS" == "rhel" || "$OS" == "almalinux" || "$OS" == "rocky" ]]; then
        sudo yum install -y curl wget firewalld
        sudo systemctl start firewalld
        sudo systemctl enable firewalld
    else
        echo "ระบบปฏิบัติการของคุณไม่รองรับสคริปต์นี้"
        exit 1
    fi
}

# ตรวจสอบว่ามีการส่งไดเรกทอรีสำหรับจัดเก็บข้อมูลหรือไม่
if [ -z "$1" ]; then
    echo "กรุณาระบุไดเรกทอรีสำหรับจัดเก็บข้อมูล MinIO เป็นอาร์กิวเมนต์แรก"
    exit 1
fi

# AccessKey และ SecretKey สำหรับ MinIO
AccessKey="abcdef1234"
SecretKey="abcdef5678"

# ตรวจสอบ OS
check_os

# ติดตั้งเครื่องมือที่จำเป็น
install_prerequisites

# ดาวน์โหลดและติดตั้ง MinIO
wget https://dl.min.io/server/minio/release/linux-amd64/minio
sudo chmod +x minio
sudo mv minio /usr/local/bin/

# สร้างไดเรกทอรีสำหรับ MinIO
sudo mkdir -p $1
sudo mkdir -p /etc/minio

# กำหนดสิทธิ์ให้กับไดเรกทอรี
sudo chown $USER:$USER $1
sudo chown $USER:$USER /etc/minio

# รับค่า IP ของโฮสต์ปัจจุบัน
HOSTIP=$(ip -o route get to 8.8.8.8 | sed -n 's/.*src \([0-9.]\+\).*/\1/p')

# สร้างไฟล์บริการ MinIO
cat <<EOF | sudo tee /etc/systemd/system/minio.service
[Unit]
Description=MinIO
Documentation=https://docs.min.io
Wants=network-online.target
After=network-online.target

[Service]
User=$USER
Group=$USER
ExecStart=/usr/local/bin/minio server $1 --config-dir /etc/minio --address ${HOSTIP}:9000 --console-address :9001
Restart=always
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

# รีโหลด systemd และเริ่มต้นบริการ MinIO
sudo systemctl daemon-reload
sudo systemctl start minio
sudo systemctl enable minio

# ตั้งค่าไฟร์วอลล์ตาม OS
if [[ "$OS" == "centos" || "$OS" == "almalinux" || "$OS" == "rocky" ]]; then
    sudo firewall-cmd --zone=public --add-port=9000/tcp --permanent
    sudo firewall-cmd --zone=public --add-port=9001/tcp --permanent
    sudo firewall-cmd --reload
else
    sudo ufw allow 9000
    sudo ufw allow 9001
    sudo ufw reload
fi

# ตั้งค่า timezone เป็น Asia/Shanghai หากมีอยู่
timezone_file="/usr/share/zoneinfo/Asia/Shanghai"
if [ -f "$timezone_file" ]; then
    current_link=$(readlink /etc/localtime)
    if [ "$current_link" != "$timezone_file" ]; then
        sudo rm -rf /etc/localtime
        sudo ln -s "$timezone_file" /etc/localtime
        echo "Timezone set to Asia/Shanghai"
    fi
fi

# แสดงผลสรุปการติดตั้ง
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
