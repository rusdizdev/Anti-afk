#!/bin/bash

# Config fix berdasarkan error di screenshot
PLAYIT_URL="https://github.com/playit-cloud/playit-agent/releases/download/v0.15.26/playit-linux-amd64"  # Pastikan URL benar
SECRET_PATH="048f23a4db9a525b7612133423757775b04acea3b89f1c7af4d8a3b2359eb8f9"  # Ganti dengan secret key Anda
LOCAL_PORT=3389
RDP_USER="runneradmin"
RDP_PASS="p@ssw0rd!"

# Langkah 1: Fix permission dan install dependencies
echo "[1/6] Memperbaiki permission dan install dependencies..."
sudo apt-get update
sudo apt-get install -y wget xrdp xorgxrdp xauth screen
sudo mkdir -p /usr/local/bin
sudo chmod 755 /usr/local/bin

# Langkah 2: Download binary playit dengan fix URL
echo "[2/6] Mengunduh playit..."
sudo wget -O /usr/local/bin/playit "$PLAYIT_URL" || {
    echo "❌ Gagal mengunduh playit, cek koneksi internet"
    exit 1
}
sudo chmod +x /usr/local/bin/playit

# Langkah 3: Fix xrdp configuration
echo "[3/6] Memperbaiki konfigurasi xrdp..."
sudo systemctl stop xrdp

# Config xrdp yang lebih stabil
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

# Langkah 4: Fix user creation
echo "[4/6] Mengatur user RDP..."
if ! id "$RDP_USER" &>/dev/null; then
    sudo useradd -m -s /bin/bash "$RDP_USER"
    echo "$RDP_USER:$RDP_PASS" | sudo chpasswd
    sudo usermod -aG sudo "$RDP_USER"
else
    echo "⚠ User $RDP_USER sudah ada, melewati pembuatan user"
fi

# Langkah 5: Fix xrdp service
echo "[5/6] Memperbaiki service xrdp..."
sudo systemctl daemon-reload
sudo systemctl restart xrdp || {
    echo "⚠ Gagal restart xrdp, coba perbaiki manual:"
    echo "sudo nano /etc/xrdp/xrdp.ini"
    echo "sudo systemctl restart xrdp"
}

# Langkah 6: Jalankan playit dengan fix parameter
echo "[6/6] Menjalankan playit..."
sudo ufw allow 3389/tcp > /dev/null 2>&1

# Gunakan absolute path dan parameter yang benar
screen -dmS playit-tunnel bash -c "/usr/local/bin/playit -s $SECRET_PATH -l $LOCAL_PORT"

# Hasil akhir
echo -e "\n✅ SETUP SELESAI"
echo "========================================"
echo "URL RDP: playit.gg/secret/$SECRET_PATH"
echo "Username: $RDP_USER"
echo "Password: $RDP_PASS"
echo "----------------------------------------"
echo "Cek status tunnel:"
echo "  screen -r playit-tunnel"
echo "  (Keluar dengan Ctrl+A kemudian D)"
echo "----------------------------------------"
echo "Jika ada error:"
echo "  Cek xrdp: sudo systemctl status xrdp"
echo "  Cek playit: screen -r playit-tunnel"
echo "========================================"
