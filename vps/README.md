# 🚀 نصب Xray VPN روی VPS

این راهنما نحوه نصب و راه‌اندازی سرور Xray VPN روی VPS را توضیح میدهد.

## 📋 پیش‌نیازها

- یک VPS با Ubuntu 20.04+ یا Debian 11+
- دسترسی SSH با root
- حداقل 512MB RAM

## 🆓 VPS رایگان

### Oracle Cloud (بهترین گزینه)

**✅ مزایا:**
- کاملاً رایگان برای همیشه
- 4 vCPU و 24GB RAM
- IP ثابت
- بدون محدودیت ترافیک

**📝 ثبت‌نام:**

1. برید به: https://www.oracle.com/cloud/free/
2. کلیک روی "Start for free"
3. اطلاعات خودتون رو وارد کنید (نیاز به کارت اعتبار داره ولی چارژ نمیکنه)
4. تایید ایمیل

**🖥️ ساخت VM:**

1. Login کنید به Oracle Cloud Console
2. Menu → Compute → Instances
3. کلیک "Create Instance"
4. انتخاب:
   - **Image:** Ubuntu 22.04
   - **Shape:** VM.Standard.A1.Flex (ARM-based, رایگان)
   - **OCPU:** 4
   - **Memory:** 24 GB
5. در قسمت "Add SSH keys" کلیک "Generate SSH key pair"
6. دانلود Private Key (فایل .key)
7. Create

**🔓 باز کردن Port 443:**

1. Instances → Instance Details
2. تب "Attached VNICs" → کلیک روی Subnet
3. Security Lists → Default Security List
4. "Add Ingress Rules":
   - **Source CIDR:** 0.0.0.0/0
   - **Destination Port:** 443
   - **Description:** Xray VPN
5. Save

**🔥 تنظیم Firewall داخل VM:**

```bash
# SSH به سرور
ssh -i Downloaded-Key.key ubuntu@YOUR_SERVER_IP

# غیرفعال کردن Oracle Firewall (باعث مشکل میشه)
sudo iptables -F
sudo netfilter-persistent save
```

### سایر VPS‌های رایگان

#### 1. **Railway.app**
- $5 کردیت رایگان
- ساده برای شروع
- https://railway.app

#### 2. **Heroku**
- 1000 ساعت رایگان/ماه
- نیاز به کارت اعتبار
- https://heroku.com

#### 3. **Google Cloud Platform**
- $300 کردیت رایگان برای 90 روز
- نیاز به کارت اعتبار
- https://cloud.google.com

---

## 🚀 نصب خودکار (یک دستور!)

بعد از اینکه به VPS خودتون SSH کردید:

```bash
sudo bash <(curl -fsSL https://raw.githubusercontent.com/Hamiaryan/free-vpn/main/vps/install.sh)
```

همین! اسکریپت:
1. ✅ Xray رو نصب میکنه
2. ✅ UUID میسازه
3. ✅ SSL Certificate میسازه
4. ✅ Firewall تنظیم میکنه
5. ✅ سرویس راه‌اندازی میکنه
6. ✅ VMess Link بهتون میده

---

## 📱 بعد از نصب

اسکریپت این اطلاعات رو بهتون میده:

```
Server IP: YOUR_SERVER_IP
Port: 443
UUID: generated-uuid
VMess Link: vmess://...
```

### استفاده:

1. **اندروید:**
   - نصب v2rayNG
   - کپی VMess Link
   - + → Import from clipboard
   - Connect

2. **iOS:**
   - نصب Shadowrocket
   - + → Type → VMess
   - Paste VMess Link
   - Connect

---

## ⚙️ مدیریت سرویس

```bash
# شروع سرویس
sudo systemctl start xray

# توقف سرویس
sudo systemctl stop xray

# ری‌استارت
sudo systemctl restart xray

# وضعیت
sudo systemctl status xray

# مشاهده لاگ
sudo journalctl -u xray -f

# اطلاعات VMess دوباره
cat /root/vpn-info.txt
```

---

## 🔧 تنظیمات پیشرفته

### تغییر UUID

```bash
# ویرایش کانفیگ
sudo nano /usr/local/xray/config.json

# پیدا کردن "id" و تغییرش
# Restart
sudo systemctl restart xray
```

### اضافه کردن کاربر جدید

```bash
sudo nano /usr/local/xray/config.json
```

در قسمت `clients` یک client جدید اضافه کنید:

```json
{
  "id": "new-uuid-here",
  "alterId": 0
}
```

---

## 🔗 اتصال به پنل VPN

اطلاعات سرور VMess را در پنل VPN وارد کنید:

```javascript
// در vpn-panel/wrangler.toml:
XRAY_SERVER = "YOUR_SERVER_IP"  # IP سرور VPS
XRAY_PORT = "443"
XRAY_PATH = "/xray"
```

سپس deploy کنید:

```bash
cd vpn-panel
wrangler deploy
```

---

## 🐛 عیب‌یابی

### سرویس شروع نمیشه

```bash
# چک لاگ
sudo journalctl -u xray -n 50

# چک کانفیگ
/usr/local/xray/xray test -c /usr/local/xray/config.json
```

### Port 443 بسته است

```bash
# چک firewall
sudo ufw status

# باز کردن port
sudo ufw allow 443/tcp
```

### اتصال timeout

```bash
# چک اینکه سرویس روشنه
sudo systemctl status xray

# چک اینکه port listen میکنه
sudo netstat -tlnp | grep 443

# تست با curl
curl -v https://YOUR_SERVER_IP
```

---

## 📞 پشتیبانی

مشکلی پیش اومد؟ Issue باز کنید:  
https://github.com/Hamiaryan/free-vpn/issues

---

**ساخته شده با ❤️ برای اینترنت آزاد**
