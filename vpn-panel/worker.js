// Cloudflare Worker - VPN Panel API
// Handles config management, usage tracking, and statistics

import { getAssetFromKV } from '@cloudflare/kv-asset-handler';

export default {
    async fetch(request, env, ctx) {
        const url = new URL(request.url);
        const path = url.pathname;

        // CORS headers
        const corsHeaders = {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type',
        };

        // Handle CORS preflight
        if (request.method === 'OPTIONS') {
            return new Response(null, { headers: corsHeaders });
        }

        try {
            // API Routes
            if (path.startsWith('/api/')) {
                if (path === '/api/configs' && request.method === 'GET') {
                    return handleGetConfigs(env, corsHeaders);
                }

                if (path === '/api/configs' && request.method === 'POST') {
                    return handleCreateConfig(request, env, corsHeaders);
                }

                if (path.startsWith('/api/configs/') && request.method === 'DELETE') {
                    const id = path.split('/')[3];
                    return handleDeleteConfig(id, env, corsHeaders);
                }

                if (path.startsWith('/api/configs/') && path.endsWith('/usage')) {
                    const id = path.split('/')[3];
                    return handleUpdateUsage(id, request, env, corsHeaders);
                }

                if (path === '/api/stats') {
                    return handleGetStats(env, corsHeaders);
                }
            }

            // Serve static files using Workers Sites
            try {
                return await getAssetFromKV(
                    {
                        request,
                        waitUntil: ctx.waitUntil.bind(ctx),
                    },
                    {
                        ASSET_NAMESPACE: env.__STATIC_CONTENT,
                        ASSET_MANIFEST: JSON.parse(env.__STATIC_CONTENT_MANIFEST),
                    }
                );
            } catch (e) {
                // If asset not found, return 404
                return new Response('Not Found', { status: 404 });
            }

        } catch (error) {
            return new Response(JSON.stringify({ error: error.message }), {
                status: 500,
                headers: { ...corsHeaders, 'Content-Type': 'application/json' }
            });
        }
    }
};

// Get all configs
async function handleGetConfigs(env, corsHeaders) {
    const { results } = await env.DB.prepare(
        'SELECT * FROM configs ORDER BY created_at DESC'
    ).all();

    return new Response(JSON.stringify(results), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
}

// Create new config
async function handleCreateConfig(request, env, corsHeaders) {
    const config = await request.json();

    await env.DB.prepare(`
        INSERT INTO configs (id, name, uuid, protocol, limit_bytes, used_bytes, expiry_date, created_at, status, server, port, path)
        VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11, ?12)
    `).bind(
        config.id,
        config.name,
        config.uuid,
        config.protocol,
        config.limit,
        config.used,
        config.expiryDate,
        config.createdAt,
        config.status,
        config.server,
        config.port,
        config.path
    ).run();

    return new Response(JSON.stringify({ success: true, config }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
}

// Delete config
async function handleDeleteConfig(id, env, corsHeaders) {
    await env.DB.prepare('DELETE FROM configs WHERE id = ?1').bind(id).run();

    return new Response(JSON.stringify({ success: true }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
}

// Update usage
async function handleUpdateUsage(id, request, env, corsHeaders) {
    const { used } = await request.json();

    await env.DB.prepare(
        'UPDATE configs SET used_bytes = ?1 WHERE id = ?2'
    ).bind(used, id).run();

    return new Response(JSON.stringify({ success: true }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
}

// Get statistics
async function handleGetStats(env, corsHeaders) {
    const { results: configs } = await env.DB.prepare('SELECT * FROM configs').all();

    const stats = {
        totalConfigs: configs.length,
        activeConfigs: configs.filter(c => c.status === 'active').length,
        totalUsage: configs.reduce((sum, c) => sum + (c.used_bytes || 0), 0),
        totalLimit: configs.reduce((sum, c) => sum + (c.limit_bytes || 0), 0)
    };

    return new Response(JSON.stringify(stats), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
}
