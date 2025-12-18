// API Configuration
const API_BASE = '/api'; // Will be handled by Cloudflare Worker

// State Management
let configs = [];

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    loadConfigs();
    setupEventListeners();
    updateStats();
});

// Event Listeners
function setupEventListeners() {
    const form = document.getElementById('create-config-form');
    if (form) {
        form.addEventListener('submit', handleCreateConfig);
    }
}

// UI Functions
function showCreateConfig() {
    const section = document.getElementById('create-config-section');
    section.style.display = 'block';
    section.scrollIntoView({ behavior: 'smooth' });
}

function hideCreateConfig() {
    const section = document.getElementById('create-config-section');
    section.style.display = 'none';
}

function scrollToConfigs() {
    document.getElementById('configs').scrollIntoView({ behavior: 'smooth' });
}

// Create Config
async function handleCreateConfig(e) {
    e.preventDefault();

    const name = document.getElementById('config-name').value;
    const limit = parseInt(document.getElementById('config-limit').value);
    const expiry = parseInt(document.getElementById('config-expiry').value);
    const protocol = document.getElementById('config-protocol').value;

    const btn = e.target.querySelector('button[type="submit"]');
    btn.disabled = true;
    btn.innerHTML = '<svg width="20" height="20" viewBox="0 0 20 20"><circle cx="10" cy="10" r="8" stroke="currentColor" stroke-width="2" fill="none" stroke-dasharray="50" stroke-dashoffset="0"><animateTransform attributeName="transform" type="rotate" from="0 10 10" to="360 10 10" dur="1s" repeatCount="indefinite"/></circle></svg> در حال ساخت...';

    try {
        // Generate UUID
        const uuid = generateUUID();

        // Calculate expiry date
        const expiryDate = new Date();
        expiryDate.setDate(expiryDate.getDate() + expiry);

        // Create config object
        const config = {
            id: Date.now().toString(),
            name,
            uuid,
            protocol,
            limit: limit === 0 ? null : limit * 1024 * 1024 * 1024, // Convert to bytes
            used: 0,
            expiryDate: expiryDate.toISOString(),
            createdAt: new Date().toISOString(),
            status: 'active',
            server: 'workspace.HamiArian.repl.co',
            port: 443,
            path: '/xray'
        };

        // Save to API (will be implemented)
        await saveConfig(config);

        // Add to local state
        configs.push(config);

        // Update UI
        renderConfigs();
        updateStats();
        hideCreateConfig();

        // Reset form
        e.target.reset();

        // Show success
        showConfigModal(config);

    } catch (error) {
        console.error('Error creating config:', error);
        alert('خطا در ساخت کانفیگ. لطفاً دوباره تلاش کنید.');
    } finally {
        btn.disabled = false;
        btn.innerHTML = '<svg width="20" height="20" viewBox="0 0 20 20" fill="none"><path d="M10 4v12m-6-6h12" stroke="currentColor" stroke-width="2" stroke-linecap="round"/></svg> ساخت کانفیگ';
    }
}

// Generate UUID
function generateUUID() {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
        const r = Math.random() * 16 | 0;
        const v = c === 'x' ? r : (r & 0x3 | 0x8);
        return v.toString(16);
    });
}

// Save Config (API call)
async function saveConfig(config) {
    // For now, save to localStorage
    // Later will be replaced with API call to Cloudflare Worker
    const savedConfigs = JSON.parse(localStorage.getItem('vpn-configs') || '[]');
    savedConfigs.push(config);
    localStorage.setItem('vpn-configs', JSON.stringify(savedConfigs));

    // TODO: Implement API call
    // await fetch(`${API_BASE}/configs`, {
    //     method: 'POST',
    //     headers: { 'Content-Type': 'application/json' },
    //     body: JSON.stringify(config)
    // });
}

// Load Configs
async function loadConfigs() {
    try {
        // For now, load from localStorage
        // Later will be replaced with API call
        const savedConfigs = JSON.parse(localStorage.getItem('vpn-configs') || '[]');
        configs = savedConfigs;

        // TODO: Implement API call
        // const response = await fetch(`${API_BASE}/configs`);
        // configs = await response.json();

        renderConfigs();
        updateStats();
    } catch (error) {
        console.error('Error loading configs:', error);
    }
}

// Render Configs
function renderConfigs() {
    const container = document.getElementById('configs-list');

    if (configs.length === 0) {
        container.innerHTML = `
            <div class="empty-state">
                <svg width="80" height="80" viewBox="0 0 80 80" fill="none">
                    <circle cx="40" cy="40" r="38" stroke="currentColor" stroke-width="2" opacity="0.2"/>
                    <path d="M40 20v40M20 40h40" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
                </svg>
                <h3>هنوز کانفیگی ندارید</h3>
                <p>برای شروع، اولین کانفیگ خودتون رو بسازید</p>
                <button class="btn btn-primary" onclick="showCreateConfig()">ساخت کانفیگ</button>
            </div>
        `;
        return;
    }

    container.innerHTML = configs.map(config => {
        const usedGB = (config.used / (1024 * 1024 * 1024)).toFixed(2);
        const limitGB = config.limit ? (config.limit / (1024 * 1024 * 1024)).toFixed(0) : '∞';
        const usagePercent = config.limit ? (config.used / config.limit * 100).toFixed(0) : 0;
        const daysLeft = Math.ceil((new Date(config.expiryDate) - new Date()) / (1000 * 60 * 60 * 24));
        const isExpired = daysLeft <= 0;
        const status = isExpired ? 'expired' : 'active';

        return `
            <div class="config-card" onclick="showConfigModal(${JSON.stringify(config).replace(/"/g, '&quot;')})">
                <div class="config-card-header">
                    <div class="config-info">
                        <h3>${config.name}</h3>
                        <div class="config-meta">
                            <span>📡 ${config.protocol.toUpperCase()}</span>
                            <span>⏰ ${daysLeft > 0 ? daysLeft + ' روز مانده' : 'منقضی شده'}</span>
                        </div>
                    </div>
                    <span class="config-status status-${status}">
                        ${status === 'active' ? 'فعال' : 'منقضی'}
                    </span>
                </div>
                
                <div class="config-stats">
                    <div class="config-stat">
                        <div class="config-stat-label">مصرف شده</div>
                        <div class="config-stat-value">${usedGB} GB</div>
                    </div>
                    <div class="config-stat">
                        <div class="config-stat-label">حد مجاز</div>
                        <div class="config-stat-value">${limitGB} GB</div>
                    </div>
                    <div class="config-stat">
                        <div class="config-stat-label">باقیمانده</div>
                        <div class="config-stat-value">${daysLeft > 0 ? daysLeft + ' روز' : '۰ روز'}</div>
                    </div>
                </div>
                
                ${config.limit ? `
                    <div class="progress-bar">
                        <div class="progress-fill" style="width: ${usagePercent}%"></div>
                    </div>
                ` : ''}
                
                <div class="config-actions">
                    <button class="btn-icon" onclick="event.stopPropagation(); copyConfig('${config.id}')">
                        📋 کپی لینک
                    </button>
                    <button class="btn-icon" onclick="event.stopPropagation(); downloadQR('${config.id}')">
                        📱 QR Code
                    </button>
                    <button class="btn-icon" onclick="event.stopPropagation(); deleteConfig('${config.id}')">
                        🗑️ حذف
                    </button>
                </div>
            </div>
        `;
    }).join('');
}

// Show Config Modal
function showConfigModal(config) {
    if (typeof config === 'string') {
        config = configs.find(c => c.id === config);
    }

    const modal = document.getElementById('config-modal');
    const title = document.getElementById('modal-title');
    const body = document.getElementById('modal-body');

    title.textContent = config.name;

    // Generate VMess link
    const vmessLink = generateVMessLink(config);

    body.innerHTML = `
        <div class="qr-container" id="qr-code"></div>
        
        <div class="form-group">
            <label>لینک اشتراک</label>
            <div class="config-link" id="config-link">${vmessLink}</div>
            <button class="btn btn-secondary btn-block" onclick="copyToClipboard('${vmessLink}')">
                📋 کپی لینک
            </button>
        </div>
        
        <div class="config-stats">
            <div class="config-stat">
                <div class="config-stat-label">سرور</div>
                <div class="config-stat-value" style="font-size: 14px;">${config.server}</div>
            </div>
            <div class="config-stat">
                <div class="config-stat-label">پورت</div>
                <div class="config-stat-value">${config.port}</div>
            </div>
            <div class="config-stat">
                <div class="config-stat-label">UUID</div>
                <div class="config-stat-value" style="font-size: 12px;">${config.uuid}</div>
            </div>
        </div>
        
        <div style="margin-top: 24px;">
            <h4 style="margin-bottom: 16px;">راهنمای استفاده</h4>
            <ol style="color: var(--text-secondary); padding-right: 20px;">
                <li>اپلیکیشن v2rayNG (اندروید) یا Shadowrocket (iOS) را نصب کنید</li>
                <li>لینک بالا را کپی کنید</li>
                <li>در اپلیکیشن، گزینه "Import from clipboard" را انتخاب کنید</li>
                <li>یا QR Code را اسکن کنید</li>
                <li>به سرور متصل شوید</li>
            </ol>
        </div>
    `;

    // Generate QR Code
    setTimeout(() => {
        const qrContainer = document.getElementById('qr-code');
        qrContainer.innerHTML = '';
        QRCode.toCanvas(vmessLink, { width: 256, margin: 2 }, (error, canvas) => {
            if (error) console.error(error);
            qrContainer.appendChild(canvas);
        });
    }, 100);

    modal.style.display = 'flex';
}

// Close Modal
function closeModal() {
    document.getElementById('config-modal').style.display = 'none';
}

// Generate VMess Link
function generateVMessLink(config) {
    const vmessConfig = {
        v: "2",
        ps: config.name,
        add: config.server,
        port: config.port.toString(),
        id: config.uuid,
        aid: "0",
        scy: "auto",
        net: "ws",
        type: "none",
        host: config.server,
        path: config.path,
        tls: "tls",
        sni: "",
        alpn: "",
        fp: ""
    };

    const jsonStr = JSON.stringify(vmessConfig);
    const base64 = btoa(unescape(encodeURIComponent(jsonStr)));
    return `vmess://${base64}`;
}

// Copy Config
function copyConfig(id) {
    const config = configs.find(c => c.id === id);
    const link = generateVMessLink(config);
    copyToClipboard(link);
}

// Copy to Clipboard
function copyToClipboard(text) {
    navigator.clipboard.writeText(text).then(() => {
        // Show toast notification
        showToast('✅ لینک کپی شد!');
    }).catch(err => {
        console.error('Failed to copy:', err);
        showToast('❌ خطا در کپی کردن');
    });
}

// Download QR Code
function downloadQR(id) {
    const config = configs.find(c => c.id === id);
    const link = generateVMessLink(config);

    QRCode.toCanvas(link, { width: 512, margin: 2 }, (error, canvas) => {
        if (error) {
            console.error(error);
            return;
        }

        canvas.toBlob((blob) => {
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = `${config.name}-qr.png`;
            a.click();
            URL.revokeObjectURL(url);
            showToast('✅ QR Code دانلود شد!');
        });
    });
}

// Delete Config
async function deleteConfig(id) {
    if (!confirm('آیا مطمئن هستید که می‌خواهید این کانفیگ را حذف کنید؟')) {
        return;
    }

    try {
        // Remove from local state
        configs = configs.filter(c => c.id !== id);

        // Update localStorage
        localStorage.setItem('vpn-configs', JSON.stringify(configs));

        // TODO: Implement API call
        // await fetch(`${API_BASE}/configs/${id}`, { method: 'DELETE' });

        renderConfigs();
        updateStats();
        showToast('✅ کانفیگ حذف شد');
    } catch (error) {
        console.error('Error deleting config:', error);
        showToast('❌ خطا در حذف کانفیگ');
    }
}

// Update Stats
function updateStats() {
    const totalConfigs = configs.length;
    const totalUsage = configs.reduce((sum, config) => sum + config.used, 0) / (1024 * 1024 * 1024);

    document.getElementById('total-configs').textContent = totalConfigs;
    document.getElementById('total-usage').textContent = totalUsage.toFixed(2) + ' GB';
}

// Show Toast
function showToast(message) {
    // Create toast element
    const toast = document.createElement('div');
    toast.style.cssText = `
        position: fixed;
        bottom: 32px;
        right: 32px;
        background: rgba(26, 26, 46, 0.95);
        backdrop-filter: blur(20px);
        color: white;
        padding: 16px 24px;
        border-radius: 12px;
        border: 1px solid rgba(255, 255, 255, 0.1);
        box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
        z-index: 10000;
        animation: slideIn 0.3s ease;
        font-weight: 500;
    `;
    toast.textContent = message;

    document.body.appendChild(toast);

    setTimeout(() => {
        toast.style.animation = 'slideOut 0.3s ease';
        setTimeout(() => toast.remove(), 300);
    }, 3000);
}

// Add CSS animations for toast
const style = document.createElement('style');
style.textContent = `
    @keyframes slideIn {
        from {
            transform: translateX(400px);
            opacity: 0;
        }
        to {
            transform: translateX(0);
            opacity: 1;
        }
    }
    
    @keyframes slideOut {
        from {
            transform: translateX(0);
            opacity: 1;
        }
        to {
            transform: translateX(400px);
            opacity: 0;
        }
    }
`;
document.head.appendChild(style);
