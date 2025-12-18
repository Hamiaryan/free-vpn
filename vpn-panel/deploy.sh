#!/bin/bash

###############################################################################
# VPN Panel Deploy Script
# Deploy پنل مدیریت VPN روی Cloudflare Workers + D1
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
║          🎨 VPN Panel - Cloudflare Deploy                ║
║          Deploy پنل مدیریت VPN                          ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

cd "$(dirname "$0")"

# Check if wrangler is installed
if ! command -v wrangler &> /dev/null; then
    echo -e "${RED}❌ Wrangler یافت نشد!${NC}"
    echo -e "${YELLOW}نصب Wrangler:${NC}"
    echo "npm install -g wrangler"
    exit 1
fi

echo -e "${BLUE}📦 در حال آماده‌سازی...${NC}"

# Create public directory
mkdir -p public
cp index.html public/
cp styles.css public/
cp app.js public/

echo -e "${GREEN}✅ فایل‌های static کپی شدند${NC}"

# Check if D1 database exists
echo -e "${BLUE}🔍 بررسی دیتابیس...${NC}"

DB_ID=$(grep "database_id" wrangler.toml | cut -d'"' -f2)

if [ "$DB_ID" = "your-database-id" ]; then
    echo -e "${YELLOW}⚠️  دیتابیس یافت نشد. در حال ساخت...${NC}"
    
    # Create D1 database
    echo -e "${BLUE}📊 ساخت D1 database...${NC}"
    wrangler d1 create vpn-configs
    
    echo -e "${YELLOW}💡 لطفاً database_id را از خروجی بالا کپی کنید و در wrangler.toml جایگذاری کنید${NC}"
    echo -e "${YELLOW}سپس دوباره این اسکریپت را اجرا کنید${NC}"
    exit 0
fi

# Run migrations
echo -e "${BLUE}📊 اجرای migrations...${NC}"
wrangler d1 execute vpn-configs --file=schema.sql

echo -e "${GREEN}✅ دیتابیس آماده شد${NC}"

# Deploy
echo -e "${BLUE}🚀 در حال deploy...${NC}"
wrangler deploy

echo -e "${GREEN}"
cat << "EOF"
═══════════════════════════════════════════════════════════
               ✨ Deploy موفقیت‌آمیز بود! ✨
═══════════════════════════════════════════════════════════
EOF
echo -e "${NC}"

# Get deployment URL
WORKER_URL=$(wrangler deployments list --name vpn-panel 2>/dev/null | grep "https://" | head -1 | awk '{print $1}' || echo "")

if [ -n "$WORKER_URL" ]; then
    echo -e "${YELLOW}🌐 URL پنل شما:${NC}"
    echo -e "${GREEN}$WORKER_URL${NC}"
    echo ""
else
    echo -e "${YELLOW}🌐 URL پنل:${NC}"
    echo -e "${GREEN}https://vpn-panel.YOUR_USERNAME.workers.dev${NC}"
    echo ""
fi

echo -e "${YELLOW}📝 مراحل بعدی:${NC}"
echo ""
echo "1. وارد URL بالا شوید"
echo "2. کانفیگ جدید بسازید"
echo "3. QR Code را اسکن کنید یا لینک را کپی کنید"
echo "4. در v2rayNG یا Shadowrocket import کنید"
echo "5. از VPN لذت ببرید! 🎉"
echo ""
echo -e "${GREEN}✨ موفق باشید! ✨${NC}"
