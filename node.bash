#!/bin/bash

# Configuration
PLAYIT_URL="https://github.com/playit-cloud/playit-agent/releases/download/v0.15.26/playit-linux-amd64"
SECRET_PATH="5046f1deb978ba6ca5c9c6ec2f658e4b24fbb8fbbe68e12fbeeec217067d79f3"  # Use your actual secret
LOCAL_PORT=3389
RDP_USER="runneradmin"
RDP_PASSWORD="p@ssw0rd!"

# Install dependencies
echo "Menginstall paket yang diperlukan..."
sudo apt-get update
sudo apt-get install -y wget xrdp xorgxrdp xauth screen

# Download PlayIt
echo "Mengunduh PlayIt..."
wget -O /tmp/playit "$PLAYIT_URL" || {
    echo "Gagal mengunduh PlayIt"
    exit 1
}
chmod +x /tmp/playit

# Configure RDP
echo "Mengkonfigurasi RDP..."
sudo systemctl stop xrdp

# Create proper xrdp configuration
sudo tee /etc/xrdp/xrdp.ini > /dev/null <<EOL
[globals]
bitmap_cache=yes
bitmap_compression=yes
port=3389
crypt_level=low
channel_code=1
max_bpp=24

[xrdp1]
name=sesman-Xvnc
lib=libvnc.so
username=ask
password=ask
ip=127.0.0.1
port=-1
EOL

# Configure XRDP
sudo sed -i 's/use_vsock=true/use_vsock=false/g' /etc/xrdp/sesman.ini
sudo sed -i '/X11DisplayOffset/a echo "exec /etc/X11/Xsession" > ~/.xsession' /etc/xrdp/startwm.sh

# Create RDP user if not exists
if ! id "$RDP_USER" &>/dev/null; then
    echo "Membuat user RDP..."
    sudo useradd -m $RDP_USER
    echo "$RDP_USER:$RDP_PASSWORD" | sudo chpasswd
    sudo usermod -aG sudo $RDP_USER
    sudo usermod -a -G ssl-cert $RDP_USER
else
    echo "User $RDP_USER sudah ada"
fi

# Start xrdp service
echo "Memulai xrdp..."
sudo systemctl restart xrdp || {
    echo "Gagal memulai xrdp"
    journalctl -xe
    exit 1
}
sudo systemctl enable xrdp

# Configure firewall
echo "Mengkonfigurasi firewall..."
sudo ufw allow 3389/tcp
sudo ufw --force enable

# Run PlayIt in screen session
echo "Menjalankan PlayIt di screen session..."
screen -dmS playit-tunnel /tmp/playit -s "$SECRET_PATH" -l "$LOCAL_PORT"

# Show connection info
echo -e "\nSetup complete!"
echo "RDP Access:"
echo "  URL: playit.gg/secret/$SECRET_PATH"
echo "  Username: $RDP_USER"
echo "  Password: $RDP_PASSWORD"
echo "  Screen session: playit-tunnel"
echo "  Untuk melihat log PlayIt: screen -r playit-tunnel"
