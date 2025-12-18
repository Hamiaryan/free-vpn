#!/bin/bash

###############################################################################
# Xray Auto-Install Script for Replit
# نصب خودکار Xray برای VPN رایگان روی Replit
###############################################################################

set -e

# رنگ‌ها
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║          🚀 Xray VPN - Replit Edition                    ║
║          نصب خودکار VPN رایگان                           ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# 1. آپدیت سیستم
echo -e "${BLUE}📦 در حال نصب ابزارها...${NC}"
apt-get update -qq > /dev/null 2>&1 || true
apt-get install -y curl wget unzip qrencode jq > /dev/null 2>&1 || true

# 2. دانلود Xray
echo -e "${BLUE}⬇️  در حال دانلود Xray...${NC}"
XRAY_VERSION=$(curl -s https://api.github.com/repos/XTLS/Xray-core/releases/latest | jq -r .tag_name 2>/dev/null || echo "v1.8.4")
echo -e "${GREEN}نسخه: $XRAY_VERSION${NC}"

DOWNLOAD_URL="https://github.com/XTLS/Xray-core/releases/download/${XRAY_VERSION}/Xray-linux-64.zip"
wget -q --show-progress "$DOWNLOAD_URL" -O /tmp/xray.zip 2>&1 || wget -q "$DOWNLOAD_URL" -O /tmp/xray.zip

# 3. استخراج
echo -e "${BLUE}📂 در حال استخراج...${NC}"
mkdir -p ~/xray
unzip -q -o /tmp/xray.zip -d ~/xray
chmod +x ~/xray/xray
rm /tmp/xray.zip

# 4. تولید UUID
echo -e "${BLUE}🔑 تولید شناسه یکتا...${NC}"
UUID=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || uuidgen || echo "$(date +%s)-$(shuf -i 1000-9999 -n 1)")
echo -e "${GREEN}UUID: $UUID${NC}"

# 5. تشخیص PORT
if [ -n "$PORT" ]; then
    XRAY_PORT=$PORT
else
    XRAY_PORT=8080
fi
echo -e "${BLUE}🔌 Port: $XRAY_PORT${NC}"

# 6. ساخت کانفیگ
echo -e "${BLUE}⚙️  ساخت کانفیگ...${NC}"

cat > ~/xray/config.json << EOF
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": $XRAY_PORT,
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "alterId": 0
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/xray"
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "tag": "direct"
    }
  ]
}
EOF

echo -e "${GREEN}✅ کانفیگ ساخته شد${NC}"

# 7. راه‌اندازی Xray
echo -e "${BLUE}🚀 راه‌اندازی Xray...${NC}"
cd ~/xray

# Kill any existing Xray process
pkill -9 xray 2>/dev/null || true

# Start Xray
./xray run -c config.json > xray.log 2>&1 &
XRAY_PID=$!
sleep 3

# 8. چک وضعیت
if ps -p $XRAY_PID > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Xray با موفقیت شروع شد (PID: $XRAY_PID)${NC}"
else
    echo -e "${RED}❌ خطا در راه‌اندازی${NC}"
    cat xray.log
    exit 1
fi

# 9. دریافت آدرس Replit
echo -e "${BLUE}🌐 در حال دریافت آدرس...${NC}"

# Try to get Replit URL from environment
if [ -n "$REPL_SLUG" ] && [ -n "$REPL_OWNER" ]; then
    SERVER_ADDRESS="${REPL_SLUG}.${REPL_OWNER}.repl.co"
else
    # Fallback to hostname
    SERVER_ADDRESS=$(hostname -f 2>/dev/null || echo "your-repl.username.repl.co")
fi

echo -e "${GREEN}📡 Server: $SERVER_ADDRESS${NC}"

# 10. ساخت لینک VMess
echo -e "${BLUE}🔗 ساخت لینک اشتراک...${NC}"

VMESS_JSON=$(cat << VMESS_EOF
{
  "v": "2",
  "ps": "Replit-Free-VPN",
  "add": "$SERVER_ADDRESS",
  "port": "$XRAY_PORT",
  "id": "$UUID",
  "aid": "0",
  "net": "ws",
  "type": "none",
  "host": "$SERVER_ADDRESS",
  "path": "/xray",
  "tls": ""
}
VMESS_EOF
)

VMESS_LINK="vmess://$(echo -n "$VMESS_JSON" | base64 -w 0 2>/dev/null || echo -n "$VMESS_JSON" | base64)"

# 11. نمایش نتایج
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}               ✨ نصب موفقیت‌آمیز بود! ✨                 ${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}📋 اطلاعات اتصال:${NC}"
echo ""
echo -e "${BLUE}پروتکل:${NC} VMess + WebSocket"
echo -e "${BLUE}سرور:${NC} $SERVER_ADDRESS"
echo -e "${BLUE}پورت:${NC} $XRAY_PORT"
echo -e "${BLUE}UUID:${NC} $UUID"
echo -e "${BLUE}Path:${NC} /xray"
echo -e "${BLUE}TLS:${NC} No (Replit handles HTTPS)"
echo ""

echo -e "${YELLOW}🔗 لینک اشتراک VMess (کپی کنید):${NC}"
echo ""
echo -e "${GREEN}$VMESS_LINK${NC}"
echo ""

# QR Code
echo -e "${YELLOW}📱 QR Code:${NC}"
echo ""
qrencode -t ANSIUTF8 "$VMESS_LINK" 2>/dev/null || echo "QR code generation skipped"
echo ""

# 12. ذخیره اطلاعات
cat > ~/xray/connection-info.txt << INFO_EOF
═══════════════════════════════════════
    🚀 Xray VPN - اطلاعات اتصال
═══════════════════════════════════════

پروتکل: VMess + WebSocket
سرور: $SERVER_ADDRESS
پورت: $XRAY_PORT
UUID: $UUID
Path: /xray
TLS: No

═══════════════════════════════════════
لینک اشتراک:
$VMESS_LINK
═══════════════════════════════════════

ساخته شده در: $(date)
INFO_EOF

echo -e "${GREEN}💾 اطلاعات در ~/xray/connection-info.txt ذخیره شد${NC}"
echo ""

echo -e "${YELLOW}📝 نکات مهم:${NC}"
echo ""
echo "  ✓ Repl باید همیشه Running باشه"
echo "  ✓ اگه Repl خاموش شد، دوباره روشن کنید"
echo "  ✓ آدرس سرور ثابته و تغییر نمیکنه"
echo "  ✓ این سرویس کاملاً رایگان است"
echo ""

echo -e "${GREEN}✨ از اینترنت آزاد لذت ببرید! ✨${NC}"
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"

# Keep the process running
wait $XRAY_PID
