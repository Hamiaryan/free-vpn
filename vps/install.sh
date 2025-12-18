#!/bin/bash

###############################################################################
# Auto VPS Setup - Xray VPN Server
# نصب خودکار Xray روی VPS (Ubuntu/Debian)
###############################################################################

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║          🚀 نصب خودکار سرور Xray VPN                    ║
║          برای VPS (Ubuntu/Debian)                        ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}❌ لطفاً با دسترسی root اجرا کنید (sudo)${NC}"
    exit 1
fi

# Detect OS
echo -e "${BLUE}🔍 شناسایی سیستم‌عامل...${NC}"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VERSION=$VERSION_ID
else
    echo -e "${RED}❌ سیستم‌عامل شناسایی نشد${NC}"
    exit 1
fi

echo -e "${GREEN}✅ OS: $OS $VERSION${NC}"

# Update system
echo -e "${BLUE}📦 بروزرسانی سیستم...${NC}"
apt-get update -qq
apt-get upgrade -y -qq

# Install dependencies
echo -e "${BLUE}📦 نصب dependencies...${NC}"
apt-get install -y wget unzip curl ufw

# Generate UUID
echo -e "${BLUE}🔑 تولید UUID...${NC}"
UUID=$(cat /proc/sys/kernel/random/uuid)
echo -e "${GREEN}✅ UUID: $UUID${NC}"

# Get server IP
SERVER_IP=$(curl -s ifconfig.me)
echo -e "${GREEN}✅ Server IP: $SERVER_IP${NC}"

# Download Xray
echo -e "${BLUE}📥 دانلود Xray...${NC}"
XRAY_VERSION="1.8.7"
wget -q https://github.com/XTLS/Xray-core/releases/download/v${XRAY_VERSION}/Xray-linux-64.zip -O /tmp/xray.zip

# Extract
echo -e "${BLUE}📂 استخراج...${NC}"
mkdir -p /usr/local/xray
unzip -q /tmp/xray.zip -d /usr/local/xray
chmod +x /usr/local/xray/xray

# Create config
echo -e "${BLUE}⚙️  ساخت کانفیگ...${NC}"
cat > /usr/local/xray/config.json << EOFCONFIG
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": 443,
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "${UUID}",
            "alterId": 0
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/xray"
        },
        "security": "tls",
        "tlsSettings": {
          "certificates": [
            {
              "certificateFile": "/usr/local/xray/cert.pem",
              "keyFile": "/usr/local/xray/key.pem"
            }
          ]
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom"
    }
  ]
}
EOFCONFIG

# Generate self-signed certificate
echo -e "${BLUE}🔐 تولید SSL Certificate...${NC}"
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /usr/local/xray/key.pem \
  -out /usr/local/xray/cert.pem \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=${SERVER_IP}" \
  2>/dev/null

# Create systemd service
echo -e "${BLUE}⚙️  ساخت systemd service...${NC}"
cat > /etc/systemd/system/xray.service << EOFSERVICE
[Unit]
Description=Xray VPN Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/xray/xray run -c /usr/local/xray/config.json
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOFSERVICE

# Configure firewall
echo -e "${BLUE}🔥 تنظیم Firewall...${NC}"
ufw --force enable
ufw allow 443/tcp
ufw allow 22/tcp
ufw reload

# Start service
echo -e "${BLUE}🚀 راه‌اندازی سرویس...${NC}"
systemctl daemon-reload
systemctl enable xray
systemctl start xray

# Wait for service to start
sleep 3

# Check status
if systemctl is-active --quiet xray; then
    echo -e "${GREEN}✅ سرویس با موفقیت راه‌اندازی شد!${NC}"
else
    echo -e "${RED}❌ خطا در راه‌اندازی سرویس${NC}"
    systemctl status xray
    exit 1
fi

# Generate VMess link
echo -e "${BLUE}🔗 تولید VMess Link...${NC}"

VMESS_CONFIG=$(cat <<EOFVMESS
{
  "v": "2",
  "ps": "VPS-VPN-Server",
  "add": "${SERVER_IP}",
  "port": "443",
  "id": "${UUID}",
  "aid": "0",
  "scy": "auto",
  "net": "ws",
  "type": "none",
  "host": "",
  "path": "/xray",
  "tls": "tls",
  "sni": "",
  "alpn": "",
  "fp": ""
}
EOFVMESS
)

VMESS_LINK="vmess://$(echo -n "$VMESS_CONFIG" | base64 -w 0)"

# Save to file
cat > /root/vpn-info.txt << EOFINFO
═══════════════════════════════════════════════════════════
          ✅ نصب Xray با موفقیت انجام شد!
═══════════════════════════════════════════════════════════

📊 اطلاعات سرور:
  Server IP: $SERVER_IP
  Port: 443
  UUID: $UUID
  Protocol: VMess + WebSocket + TLS
  Path: /xray

🔗 VMess Link (کپی کنید):
$VMESS_LINK

📱 استفاده:
  1. نصب v2rayNG (Android) یا Shadowrocket (iOS)
  2. Import لینک بالا
  3. Connect

⚙️  مدیریت سرویس:
  شروع: systemctl start xray
  توقف: systemctl stop xray
  وضعیت: systemctl status xray
  لاگ: journalctl -u xray -f

🔄 آپدیت کانفیگ:
  ویرایش: nano /usr/local/xray/config.json
  Restart: systemctl restart xray

═══════════════════════════════════════════════════════════
EOFINFO

# Display info
cat /root/vpn-info.txt

echo -e "${GREEN}"
cat << "EOF"

╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║          🎉 نصب با موفقیت انجام شد!                     ║
║                                                           ║
║  اطلاعات در فایل /root/vpn-info.txt ذخیره شد           ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${YELLOW}💡 برای مشاهده دوباره اطلاعات: cat /root/vpn-info.txt${NC}"
