#!/bin/bash

###############################################################################
# Xray Auto-Install Script for GitHub Codespaces
# نصب خودکار Xray برای VPN رایگان
###############################################################################

set -e

# رنگ‌ها برای خروجی زیبا
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# توابع کمکی
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# بنر شروع
clear
echo -e "${GREEN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║          🚀 Xray VPN Auto-Installer                      ║
║          GitHub Codespaces Edition                        ║
║          نصب خودکار VPN رایگان                           ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# چک کردن دسترسی root
if [ "$EUID" -ne 0 ]; then 
    print_warning "در حال اجرا بدون دسترسی root..."
    SUDO="sudo"
else
    SUDO=""
fi

# 1. آپدیت سیستم
print_info "در حال آپدیت سیستم..."
$SUDO apt-get update -qq > /dev/null 2>&1
print_success "سیستم آپدیت شد"

# 2. نصب ابزارهای مورد نیاز
print_info "نصب ابزارهای مورد نیاز..."
$SUDO apt-get install -y curl wget unzip qrencode jq > /dev/null 2>&1
print_success "ابزارها نصب شدند"

# 3. دانلود و نصب Xray
print_info "در حال دانلود Xray..."
XRAY_VERSION=$(curl -s https://api.github.com/repos/XTLS/Xray-core/releases/latest | jq -r .tag_name)
print_info "آخرین نسخه: $XRAY_VERSION"

# تشخیص معماری
ARCH=$(uname -m)
case $ARCH in
    x86_64)
        XRAY_ARCH="linux-64"
        ;;
    aarch64)
        XRAY_ARCH="linux-arm64-v8a"
        ;;
    *)
        print_error "معماری پشتیبانی نمیشود: $ARCH"
        exit 1
        ;;
esac

# دانلود Xray
DOWNLOAD_URL="https://github.com/XTLS/Xray-core/releases/download/${XRAY_VERSION}/Xray-${XRAY_ARCH}.zip"
wget -q --show-progress "$DOWNLOAD_URL" -O /tmp/xray.zip

# استخراج
print_info "در حال استخراج فایل‌ها..."
mkdir -p ~/xray
unzip -q /tmp/xray.zip -d ~/xray
chmod +x ~/xray/xray
rm /tmp/xray.zip
print_success "Xray نصب شد"

# 4. تولید UUID برای کاربر
print_info "تولید شناسه یکتا (UUID)..."
UUID=$(cat /proc/sys/kernel/random/uuid)
print_success "UUID: $UUID"

# 5. ساخت کانفیگ Xray
print_info "در حال ساخت کانفیگ..."

# انتخاب پروتکل (VMess + WebSocket)
PORT=8080

cat > ~/xray/config.json << EOF
{
  "log": {
    "loglevel": "warning"
  },
  "routing": {
    "domainStrategy": "AsIs",
    "rules": [
      {
        "type": "field",
        "ip": ["geoip:private"],
        "outboundTag": "block"
      }
    ]
  },
  "inbounds": [
    {
      "port": $PORT,
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
    },
    {
      "protocol": "blackhole",
      "tag": "block"
    }
  ]
}
EOF

print_success "کانفیگ ساخته شد"

# 6. راه‌اندازی Xray
print_info "راه‌اندازی سرور Xray..."
cd ~/xray
nohup ./xray run -c config.json > xray.log 2>&1 &
XRAY_PID=$!
sleep 2

# چک کردن وضعیت
if ps -p $XRAY_PID > /dev/null; then
    print_success "Xray با موفقیت شروع شد (PID: $XRAY_PID)"
else
    print_error "خطا در راه‌اندازی Xray"
    cat xray.log
    exit 1
fi

# 7. دریافت آدرس Public
print_info "در حال دریافت آدرس عمومی..."

# استفاده از Codespaces forwarded port
if [ -n "$CODESPACE_NAME" ]; then
    # در Codespaces هستیم
    SERVER_ADDRESS="${CODESPACE_NAME}-${PORT}.preview.app.github.dev"
    print_success "آدرس Codespace شما: $SERVER_ADDRESS"
else
    # خارج از Codespaces - استفاده از IP عمومی
    SERVER_ADDRESS=$(curl -s ifconfig.me)
    print_warning "از IP عمومی استفاده میشود: $SERVER_ADDRESS"
fi

# 8. ساخت لینک اشتراک VMess
print_info "ساخت لینک اشتراک..."

VMESS_JSON=$(cat << EOF
{
  "v": "2",
  "ps": "GitHub-Codespaces-Free-VPN",
  "add": "$SERVER_ADDRESS",
  "port": "$PORT",
  "id": "$UUID",
  "aid": "0",
  "net": "ws",
  "type": "none",
  "host": "",
  "path": "/xray",
  "tls": "tls"
}
EOF
)

VMESS_LINK="vmess://$(echo -n "$VMESS_JSON" | base64 -w 0)"

# 9. نمایش نتایج
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}               ✨ نصب با موفقیت کامل شد! ✨                ${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""

print_success "اطلاعات اتصال:"
echo ""
echo -e "${YELLOW}📋 پروتکل:${NC} VMess + WebSocket + TLS"
echo -e "${YELLOW}🌐 سرور:${NC} $SERVER_ADDRESS"
echo -e "${YELLOW}🔌 پورت:${NC} $PORT"
echo -e "${YELLOW}🆔 UUID:${NC} $UUID"
echo -e "${YELLOW}🛤️  Path:${NC} /xray"
echo -e "${YELLOW}🔐 TLS:${NC} Enable"
echo ""

print_info "لینک اشتراک VMess (کپی کنید):"
echo ""
echo -e "${BLUE}$VMESS_LINK${NC}"
echo ""

# ساخت QR Code
print_info "QR Code برای موبایل:"
echo ""
qrencode -t ANSIUTF8 "$VMESS_LINK"
echo ""

# ذخیره اطلاعات
cat > ~/xray/connection-info.txt << EOF
═══════════════════════════════════════
    🚀 Xray VPN - اطلاعات اتصال
═══════════════════════════════════════

پروتکل: VMess + WebSocket + TLS
سرور: $SERVER_ADDRESS
پورت: $PORT
UUID: $UUID
Path: /xray
TLS: Enable

═══════════════════════════════════════
لینک اشتراک:
$VMESS_LINK
═══════════════════════════════════════

ساخته شده در: $(date)
EOF

print_success "اطلاعات در ~/xray/connection-info.txt ذخیره شد"

# دستورات مدیریت
echo ""
print_info "دستورات مفید:"
echo ""
echo -e "  ${YELLOW}مشاهده لاگ:${NC}       tail -f ~/xray/xray.log"
echo -e "  ${YELLOW}توقف سرویس:${NC}      kill $XRAY_PID"
echo -e "  ${YELLOW}ری‌استارت:${NC}        cd ~/xray && ./xray run -c config.json"
echo -e "  ${YELLOW}اطلاعات اتصال:${NC}    cat ~/xray/connection-info.txt"
echo ""

# نکات مهم
print_warning "⚡ نکات مهم:"
echo ""
echo "  ✓ این Codespace بعد از 30 دقیقه idle خاموش میشه"
echo "  ✓ برای استفاده دوباره، Codespace رو restart کنید"
echo "  ✓ آدرس سرور ممکنه بعد از restart عوض بشه"
echo "  ✓ از 60-120 ساعت رایگان ماهانه هوشمندانه استفاده کنید"
echo ""

# راهنمای نصب کلاینت
print_info "📱 نصب کلاینت:"
echo ""
echo "  اندروید: v2rayNG"
echo "  iOS: Shadowrocket یا Streisand"
echo "  ویندوز: v2rayN"
echo "  مک: V2RayX یا Qv2ray"
echo "  لینوکس: Qv2ray"
echo ""
echo "  لینک اشتراک بالا رو کپی کنید و در کلاینت paste کنید"
echo ""

print_success "✨ همه چیز آماده است! از اینترنت آزاد لذت ببرید! ✨"

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
