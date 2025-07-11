#!/bin/bash

# Configuration
PLAYIT_URL="https://github.com/playit-cloud/playit-agent/releases/download/v0.15.26/playit-linux-amd64"
SECRET_PATH="5046f1deb078ba6ca5c9c6ec2f650e4b24fbb8fbbe60e12fbeeec217067d79f3"  # Replace with your secret path
LOCAL_PORT=3389              # Default RDP port
RDP_USER="runneradmin"
RDP_PASSWORD="p@ssw0rd!"     # Change to a secure password

# Install dependencies
echo "Installing required packages..."
sudo apt-get update
sudo apt-get install -y wget xrdp

# Download and install Playit
echo "Downloading Playit..."
if ! wget -O /tmp/playit "$PLAYIT_URL"; then
    echo "Failed to download Playit"
    exit 1
fi
chmod +x /tmp/playit

# Configure RDP (equivalent to Enable TS step)
echo "Configuring RDP..."
sudo systemctl stop xrdp
sudo sed -i 's/port=3389/port=3390/g' /etc/xrdp/xrdp.ini  # Change default port to avoid conflict
sudo systemctl start xrdp
sudo systemctl enable xrdp

# Create RDP user (equivalent to Set-LocalUser)
echo "Creating RDP user..."
sudo useradd -m $RDP_USER
echo "$RDP_USER:$RDP_PASSWORD" | sudo chpasswd
sudo usermod -aG sudo $RDP_USER

# Configure firewall (equivalent to Enable-NetFirewallRule)
echo "Configuring firewall..."
sudo ufw allow 3389/tcp
sudo ufw allow 3390/tcp  # For xrdp
sudo ufw --force enable

# Start Playit tunnel (equivalent to Start Playit and Set Up My node)
echo "Starting Playit tunnel..."
nohup /tmp/playit -secret-path "$SECRET_PATH" -local-port "$LOCAL_PORT" > /tmp/playit.log 2>&1 &

echo "Setup complete!"
echo "RDP Access:"
echo "  URL: playit.gg/secret/$SECRET_PATH"
echo "  Username: $RDP_USER"
echo "  Password: $RDP_PASSWORD"
echo "Playit logs: /tmp/playit.log"
