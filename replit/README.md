# 🚀 راهنمای کامل ساخت VPN رایگان با Replit

## 🎯 چرا Replit؟

- ✅ **100% رایگان** - بدون نیاز به کارت
- ✅ **کانفیگ VMess** - کار میکنه با v2rayNG
- ✅ **راه‌اندازی 5 دقیقه‌ای**
- ✅ **از ایران قابل دسترسی**
- ✅ **آدرس ثابت** - تغییر نمیکنه

---

## 📋 مراحل نصب

### گام 1: ساخت اکانت Replit

1. برید به: https://replit.com/signup
2. Sign up کنید با:
   - Google Account (ساده‌ترین راه)
   - یا GitHub
   - یا ایمیل

### گام 2: ساخت Repl جدید

1. بعد از لاگین، کلیک روی **+ Create Repl**
2. Template: **Bash** انتخاب کنید
3. Title: **vpn-server** (یا هر اسمی که دوست دارید)
4. کلیک روی **Create Repl**

### گام 3: آپلود اسکریپت

در Repl که باز شد:

1. سمت چپ، در قسمت Files، روی **Upload file** کلیک کنید
2. فایل `setup-xray.sh` رو از پروژه VPN آپلود کنید
   - مسیر: `/Users/hami/iCloud Drive (Archive)/Desktop/vpn/replit/setup-xray.sh`

یا میتونید محتوای فایل رو کپی/پیست کنید:

1. یک فایل جدید بسازید: `setup-xray.sh`
2. محتوای اسکریپت رو کپی کنید و paste کنید
3. Save کنید

### گام 4: اجرای اسکریپت

در **Shell** (پایین صفحه Replit):

```bash
chmod +x setup-xray.sh
./setup-xray.sh
```

منتظر بمونید... (1-2 دقیقه)

### گام 5: کپی لینک VMess

بعد از اتمام نصب، یک **لینک vmess://** نشون داده میشه.

```
vmess://eyJ2IjoiMiIsInBzIjoi...
```

این لینک رو **کپی کنید**!

---

## 📱 استفاده در موبایل

### اندروید - v2rayNG

1. نصب [v2rayNG](https://github.com/2dust/v2rayNG/releases)
2. باز کردن اپ
3. کلیک روی **+** بالا
4. انتخاب **Import config from clipboard**
5. لینک vmess که کپی کردید خودکار paste میشه
6. کلیک روی کانفیگ → **Connect**

### iOS - Shadowrocket

1. نصب Shadowrocket ($2.99)
2. باز کردن اپ
3. **+** → Type: **Subscribe**
4. Paste لینک vmess
5. Save و Connect

### ویندوز - v2rayN

1. دانلود [v2rayN](https://github.com/2dust/v2rayN/releases)
2. اجرا → Servers → Import from clipboard
3. Paste لینک vmess
4. Right click روی سرور → Set as active server

---

## ⚙️ تنظیمات مهم Replit

### نگه داشتن Repl Always Running

**مشکل:** Replit بعد از مدتی idle، Repl رو خاموش میکنه.

**راه‌حل 1: UptimeRobot**

1. برید به: https://uptimerobot.com
2. ثبت‌نام رایگان
3. Add New Monitor:
   - Type: HTTP(s)
   - URL: آدرس Repl شما (مثلاً `https://vpn-server.username.repl.co`)
   - Monitoring Interval: 5 minutes
4. Save

این سرویس هر 5 دقیقه یک request میفرسته و Repl رو زنده نگه میداره.

**راه‌حل 2: Always On (پولی - $7/ماه)**

اگه بودجه دارید، میتونید از Always On Replit استفاده کنید.

---

## 🐛 رفع مشکلات

### مشکل 1: Repl خاموش میشه

**راه‌حل:**
- از UptimeRobot استفاده کنید
- یا هر چند ساعت یک بار Repl رو باز کنید

### مشکل 2: اتصال برقرار نمیشه

**راه‌حل:**
1. چک کنید Repl Running است؟
2. در Shell بزنید: `ps aux | grep xray`
3. اگه خاموش بود: `./setup-xray.sh`

### مشکل 3: لینک vmess کار نمیکنه

**راه‌حل:**
1. در Repl، فایل `~/xray/connection-info.txt` رو باز کنید
2. لینک جدید رو کپی کنید
3. دوباره در اپ import کنید

### مشکل 4: سرعت پایین

**راه‌حل:**
- Replit Free tier سرعت محدود داره
- برای سرعت بهتر باید Hacker plan بگیرید ($7/ماه)
- یا از سرویس‌های دیگه استفاده کنید

---

## 📊 محدودیت‌های Replit Free

| مورد | محدودیت |
|------|---------|
| CPU | محدود |
| RAM | 500MB-1GB |
| Storage | 500MB |
| Uptime | تا زمانی که Active باشه |
| Bandwidth | محدود (برای استفاده معمولی کافیه) |

---

## 💡 نکات مهم

### ✅ چیزایی که کار میکنن:
- وب سرفینگ
- تلگرام
- اینستاگرام
- یوتیوب
- تمام اپلیکیشن‌ها

### ⚠️ نکات:
- Repl باید Running باشه
- از UptimeRobot استفاده کنید
- لینک vmess رو جای امن ذخیره کنید

---

## 🔄 Restart کردن

اگه Xray خاموش شد:

```bash
cd ~/xray
./xray run -c config.json &
```

یا دوباره اسکریپت رو اجرا کنید:

```bash
./setup-xray.sh
```

---

## 🆚 مقایسه با سرویس‌های دیگه

| سرویس | رایگان؟ | نیاز به کارت؟ | Uptime |
|--------|---------|---------------|--------|
| **Replit** | ✅ بله | ❌ خیر | با UptimeRobot |
| **Railway** | $5 credit | ✅ بله | 24/7 |
| **Render** | 750h/ماه | ❌ خیر | محدود |
| **GitHub Codespaces** | 120h/ماه | ✅ بله (برخی) | On-demand |

---

## 🚀 مراحل خلاصه

1. ✅ ثبت‌نام در Replit
2. ✅ Create Repl (Bash template)
3. ✅ آپلود `setup-xray.sh`
4. ✅ اجرای اسکریپت
5. ✅ کپی لینک vmess
6. ✅ Import در v2rayNG
7. ✅ Connect و لذت ببرید!

---

**موفق باشید!** 🎉

برای کمک بیشتر به مستندات اصلی مراجعه کنید.
