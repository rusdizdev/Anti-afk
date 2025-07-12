#!/bin/bash

# Configuration
PLAYIT_URL="https://github.com/playit-cloud/playit-agent/releases/download/v0.15.26/playit-linux-amd64"
SECRET_PATH="5046f1deb078ba6ca5c9c6ec2f650e4b24fbb8fbbe60e12fbeeec217067d79f3"  # Ganti dengan secret path Anda
LOCAL_PORT=3389              # Port RDP default
RDP_USER="runneradmin"
RDP_PASSWORD="p@ssw0rd!"     # Ganti dengan password yang lebih aman

# Install dependencies
echo "Menginstal paket yang diperlukan..."
sudo apt-get update
sudo apt-get install -y wget xrdp xorgxrdp xauth

# Download PlayIt
echo "Mengunduh PlayIt..."
if ! wget -O /tmp/playit "$PLAYIT_URL"; then
    echo "Gagal mengunduh PlayIt"
    exit 1
fi
chmod +x /tmp/playit

# Konfigurasi RDP dasar
sudo systemctl stop xrdp
sudo tee /etc/xrdp/xrdp.ini > /dev/null <<EOL
[globals]
bitmap_cache=yes
port=3389

[xrdp1]
name=sesman-Xvnc
lib=libvnc.so
ip=127.0.0.1
port=-1
EOL

# Buat user RDP
sudo useradd -m $RDP_USER
echo "$RDP_USER:$RDP_PASSWORD" | sudo chpasswd
sudo usermod -aG sudo $RDP_USER

# Mulai ulang xrdp
sudo systemctl restart xrdp

# Jalankan PlayIt dan tampilkan output aslinya
echo "Menjalankan PlayIt dengan output langsung..."
echo "-------------------------------------------"
exec /tmp/playit -secret-path "$SECRET_PATH" -local-port "$LOCAL_PORT"
