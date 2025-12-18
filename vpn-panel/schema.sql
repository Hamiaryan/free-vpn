-- Database schema for VPN Panel
-- Cloudflare D1 Database

-- Configs table
CREATE TABLE IF NOT EXISTS configs (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    uuid TEXT NOT NULL UNIQUE,
    protocol TEXT NOT NULL DEFAULT 'vmess',
    limit_bytes INTEGER,
    used_bytes INTEGER DEFAULT 0,
    expiry_date TEXT NOT NULL,
    created_at TEXT NOT NULL,
    status TEXT DEFAULT 'active',
    server TEXT NOT NULL,
    port INTEGER NOT NULL,
    path TEXT NOT NULL
);

-- Usage logs table (for detailed tracking)
CREATE TABLE IF NOT EXISTS usage_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    config_id TEXT NOT NULL,
    bytes_used INTEGER NOT NULL,
    timestamp TEXT NOT NULL,
    FOREIGN KEY (config_id) REFERENCES configs(id) ON DELETE CASCADE
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_configs_status ON configs(status);
CREATE INDEX IF NOT EXISTS idx_configs_created_at ON configs(created_at);
CREATE INDEX IF NOT EXISTS idx_usage_logs_config_id ON usage_logs(config_id);
CREATE INDEX IF NOT EXISTS idx_usage_logs_timestamp ON usage_logs(timestamp);
