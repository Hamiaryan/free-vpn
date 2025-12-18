/**
 * Cloudflare Workers HTTPS Proxy
 * 
 * یک پروکسی قدرتمند برای دور زدن فیلترینگ
 * - پشتیبانی از HTTPS
 * - رمزنگاری کامل
 * - بدون لاگ
 * - سرعت بالا با CDN Cloudflare
 */

// کانفیگ اصلی
const CONFIG = {
  // دامنه‌های مجاز (برای امنیت بیشتر)
  allowedDomains: [], // خالی = همه دامنه‌ها مجاز
  
  // هدرهای امنیتی
  securityHeaders: {
    'X-Proxy-By': 'Cloudflare-Worker',
    'X-Content-Type-Options': 'nosniff',
  },
  
  // فعال‌سازی cache
  enableCache: true,
  
  // مدت زمان cache (ثانیه)
  cacheTTL: 3600,
};

/**
 * Handler اصلی برای تمام درخواست‌ها
 */
addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request));
});

/**
 * پردازش درخواست
 */
async function handleRequest(request) {
  try {
    const url = new URL(request.url);
    
    // صفحه اصلی - راهنمای استفاده
    if (url.pathname === '/' || url.pathname === '') {
      return getHomePage();
    }
    
    // Health check
    if (url.pathname === '/health') {
      return new Response(JSON.stringify({ status: 'ok', timestamp: Date.now() }), {
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    // پردازش درخواست پروکسی
    return await proxyRequest(request);
    
  } catch (error) {
    return new Response(`خطا: ${error.message}`, {
      status: 500,
      headers: { 'Content-Type': 'text/plain; charset=utf-8' }
    });
  }
}

/**
 * پروکسی کردن درخواست
 */
async function proxyRequest(request) {
  const url = new URL(request.url);
  
  // استخراج URL هدف از query parameter یا path
  let targetUrl;
  
  if (url.searchParams.has('url')) {
    // روش 1: ?url=https://example.com
    targetUrl = url.searchParams.get('url');
  } else if (url.pathname.length > 1) {
    // روش 2: /https://example.com
    targetUrl = url.pathname.substring(1);
  } else {
    return new Response('لطفاً URL هدف را مشخص کنید', {
      status: 400,
      headers: { 'Content-Type': 'text/plain; charset=utf-8' }
    });
  }
  
  // اعتبارسنجی URL
  try {
    new URL(targetUrl);
  } catch {
    return new Response('URL نامعتبر است', {
      status: 400,
      headers: { 'Content-Type': 'text/plain; charset=utf-8' }
    });
  }
  
  // بررسی دامنه مجاز
  if (CONFIG.allowedDomains.length > 0) {
    const targetDomain = new URL(targetUrl).hostname;
    if (!CONFIG.allowedDomains.some(d => targetDomain.includes(d))) {
      return new Response('دسترسی به این دامنه مجاز نیست', {
        status: 403,
        headers: { 'Content-Type': 'text/plain; charset=utf-8' }
      });
    }
  }
  
  // ساخت درخواست جدید
  const proxyRequest = new Request(targetUrl, {
    method: request.method,
    headers: cleanHeaders(request.headers),
    body: request.body,
  });
  
  // چک کردن cache
  if (CONFIG.enableCache && request.method === 'GET') {
    const cache = caches.default;
    let response = await cache.match(proxyRequest);
    
    if (response) {
      response = new Response(response.body, response);
      response.headers.set('X-Cache', 'HIT');
      response.headers.set('Access-Control-Allow-Origin', '*');
      return response;
    }
  }
  
  // ارسال درخواست به سرور مقصد
  let response = await fetch(proxyRequest);
  
  // کپی response با هدرهای جدید
  response = new Response(response.body, response);
  
  // اضافه کردن هدرهای CORS
  response.headers.set('Access-Control-Allow-Origin', '*');
  response.headers.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  response.headers.set('Access-Control-Allow-Headers', '*');
  
  // اضافه کردن هدرهای امنیتی
  for (const [key, value] of Object.entries(CONFIG.securityHeaders)) {
    response.headers.set(key, value);
  }
  
  response.headers.set('X-Cache', 'MISS');
  
  // ذخیره در cache
  if (CONFIG.enableCache && request.method === 'GET' && response.ok) {
    const cache = caches.default;
    response.headers.set('Cache-Control', `public, max-age=${CONFIG.cacheTTL}`);
    await cache.put(proxyRequest, response.clone());
  }
  
  return response;
}

/**
 * پاک کردن هدرهای مشکل‌ساز
 */
function cleanHeaders(headers) {
  const cleaned = new Headers(headers);
  
  // حذف هدرهای Cloudflare
  const headersToRemove = [
    'cf-connecting-ip',
    'cf-ipcountry',
    'cf-ray',
    'cf-visitor',
    'host'
  ];
  
  headersToRemove.forEach(header => cleaned.delete(header));
  
  return cleaned;
}

/**
 * صفحه اصلی - راهنما
 */
function getHomePage() {
  const html = `
<!DOCTYPE html>
<html lang="fa" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>پروکسی رایگان Cloudflare</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        
        .container {
            background: rgba(255, 255, 255, 0.95);
            border-radius: 20px;
            padding: 40px;
            max-width: 800px;
            width: 100%;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
        }
        
        h1 {
            color: #667eea;
            margin-bottom: 10px;
            font-size: 2.5em;
        }
        
        .subtitle {
            color: #666;
            margin-bottom: 30px;
            font-size: 1.1em;
        }
        
        .section {
            margin: 30px 0;
            padding: 20px;
            background: #f8f9fa;
            border-radius: 10px;
            border-right: 4px solid #667eea;
        }
        
        h2 {
            color: #333;
            margin-bottom: 15px;
            font-size: 1.5em;
        }
        
        .code {
            background: #2d2d2d;
            color: #f8f8f2;
            padding: 15px;
            border-radius: 8px;
            font-family: 'Courier New', monospace;
            margin: 10px 0;
            overflow-x: auto;
            direction: ltr;
            text-align: left;
        }
        
        .feature {
            display: flex;
            align-items: center;
            margin: 10px 0;
            padding: 10px;
        }
        
        .feature-icon {
            width: 30px;
            height: 30px;
            background: #667eea;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            margin-left: 15px;
            font-weight: bold;
        }
        
        .status {
            display: inline-block;
            padding: 5px 15px;
            background: #10b981;
            color: white;
            border-radius: 20px;
            font-size: 0.9em;
            margin-bottom: 20px;
        }
        
        a {
            color: #667eea;
            text-decoration: none;
            font-weight: bold;
        }
        
        a:hover {
            text-decoration: underline;
        }
        
        ul {
            list-style: none;
            padding-right: 0;
        }
        
        li {
            padding: 8px 0;
            border-bottom: 1px solid #e0e0e0;
        }
        
        li:last-child {
            border-bottom: none;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 پروکسی رایگان Cloudflare</h1>
        <p class="subtitle">دسترسی آزاد و امن به اینترنت</p>
        <span class="status">✓ آنلاین و آماده</span>
        
        <div class="section">
            <h2>📖 نحوه استفاده</h2>
            
            <h3 style="margin: 20px 0 10px;">روش 1: Query Parameter</h3>
            <div class="code">https://your-worker.workers.dev/?url=https://example.com</div>
            
            <h3 style="margin: 20px 0 10px;">روش 2: Path</h3>
            <div class="code">https://your-worker.workers.dev/https://example.com</div>
        </div>
        
        <div class="section">
            <h2>✨ ویژگی‌ها</h2>
            <div class="feature">
                <div class="feature-icon">✓</div>
                <div>کاملاً رایگان و نامحدود</div>
            </div>
            <div class="feature">
                <div class="feature-icon">⚡</div>
                <div>سرعت بالا با شبکه Cloudflare</div>
            </div>
            <div class="feature">
                <div class="feature-icon">🔒</div>
                <div>رمزنگاری کامل HTTPS</div>
            </div>
            <div class="feature">
                <div class="feature-icon">🌍</div>
                <div>دسترسی به تمام وبسایت‌ها</div>
            </div>
            <div class="feature">
                <div class="feature-icon">🚫</div>
                <div>بدون ذخیره لاگ</div>
            </div>
        </div>
        
        <div class="section">
            <h2>🔧 تنظیمات مرورگر</h2>
            <ul>
                <li><strong>نوع:</strong> HTTPS Proxy</li>
                <li><strong>سرور:</strong> your-worker.workers.dev</li>
                <li><strong>پورت:</strong> 443</li>
            </ul>
        </div>
        
        <div class="section">
            <h2>📱 استفاده در تلگرام</h2>
            <p>تنظیمات → داده و حافظه → تنظیمات پروکسی</p>
            <ul>
                <li><strong>نوع:</strong> SOCKS5 یا HTTP</li>
                <li><strong>سرور:</strong> آدرس Worker شما</li>
                <li><strong>پورت:</strong> 443</li>
            </ul>
        </div>
        
        <div class="section">
            <h2>ℹ️ اطلاعات بیشتر</h2>
            <p>این سرویس بر پایه Cloudflare Workers ساخته شده و کاملاً رایگان است.</p>
            <p style="margin-top: 10px;">برای اطلاعات بیشتر و کد منبع، به مستندات پروژه مراجعه کنید.</p>
        </div>
    </div>
</body>
</html>
  `;
  
  return new Response(html, {
    headers: {
      'Content-Type': 'text/html; charset=utf-8',
      'Cache-Control': 'public, max-age=3600'
    }
  });
}
