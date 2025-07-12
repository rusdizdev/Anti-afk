#!/bin/bash

# Config yang disesuaikan dengan error di screenshot
PLAYIT_URL="https://github.com/playit-cloud/playit-agent/releases/download/v0.15.26/playit-linux-amd64"
SECRET_PATH="5046f1deb978ba6ca5c9c6ec2f658e4b24fbb8fbbe68e12fbeeec217067d79f3"  # Pakai secret dari screenshot
LOCAL_PORT=3389
RDP_USER="runneradmin"
RDP_PASS="p@ssw0rd!"

# Langkah 1: Pastikan semua dependencies terinstall
echo "[1/5] Memastikan dependencies terinstall..."
sudo apt-get update
sudo apt-get install -y wget xrdp xorgxrdp xauth screen > /dev/null 2>&1

# Langkah 2: Download binary playit
echo "[2/5] Mengunduh playit..."
if ! wget -q --show-progress -O /usr/local/bin/playit "$PLAYIT_URL"; then
    echo "❌ Gagal mengunduh playit"
    exit 1
fi
chmod +x /usr/local/bin/playit

# Langkah 3: Setup xrdp (diperbaiki dari error di screenshot)
echo "[3/5] Menyiapkan xrdp..."
sudo systemctl stop xrdp > /dev/null 2>&1

# Config xrdp yang lebih kompatibel
sudo tee /etc/xrdp/xrdp.ini > /dev/null <<EOL
[globals]
bitmap_cache=yes
bitmap_compression=yes
port=3389
crypt_level=low
channel_code=1
max_bpp=24

[xrdp1]
name=MyRDP
lib=libvnc.so
username=ask
password=ask
ip=127.0.0.1
port=-1
EOL

# Langkah 4: Buat user (handle case user sudah ada)
echo "[4/5] Membuat user RDP..."
if ! id "$RDP_USER" &>/dev/null; then
    sudo useradd -m -s /bin/bash "$RDP_USER"
    echo "$RDP_USER:$RDP_PASS" | sudo chpasswd
    sudo usermod -aG sudo "$RDP_USER"
else
    echo "⚠ User $RDP_USER sudah ada, melewati pembuatan user"
fi

# Langkah 5: Jalankan playit di screen (fix dari error screenshot)
echo "[5/5] Menjalankan playit..."
sudo systemctl restart xrdp
sudo ufw allow 3389/tcp > /dev/null 2>&1

# Jalankan di screen dengan parameter yang benar
screen -dmS playit-tunnel bash -c "playit -s $SECRET_PATH -l $LOCAL_PORT"

# Hasil akhir
echo -e "\n✅ SETUP SELESAI"
echo "========================================"
echo "URL RDP: playit.gg/secret/$SECRET_PATH"
echo "Username: $RDP_USER"
echo "Password: $RDP_PASS"
echo "----------------------------------------"
echo "Perintah penting:"
echo "  Lihat log tunnel: screen -r playit-tunnel"
echo "  Keluar dari screen: Ctrl+A, lalu D"
echo "  Cek status xrdp: sudo systemctl status xrdp"
echo "========================================"
