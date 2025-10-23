#!/bin/bash

set -euo pipefail

MARIADB_ROOT_PASSWORD=${MARIADB_ROOT_PASSWORD:-}
FRAPPE_ADMIN_PASSWORD=${FRAPPE_ADMIN_PASSWORD:-}
FRAPPE_SITE_NAME=${FRAPPE_SITE_NAME:-localhost}
FRAPPE_DEFAULT_SITE=${FRAPPE_DEFAULT_SITE:-$FRAPPE_SITE_NAME}
FRAPPE_DEVELOPER_MODE=${FRAPPE_DEVELOPER_MODE:-1}
FRAPPE_MUTE_EMAILS=${FRAPPE_MUTE_EMAILS:-1}
FRAPPE_DB_NAME=${FRAPPE_DB_NAME:-}
FRAPPE_DB_PASSWORD=${FRAPPE_DB_PASSWORD:-}
FRAPPE_ENCRYPTION_KEY=${FRAPPE_ENCRYPTION_KEY:-}
FRAPPE_BENCH_VERSION=${FRAPPE_BENCH_VERSION:-version-15}
YARN_NETWORK_TIMEOUT=${YARN_NETWORK_TIMEOUT:-100000}
FRAPPE_DOMAIN=${FRAPPE_DOMAIN:-}

if [ -z "$MARIADB_ROOT_PASSWORD" ]; then
    echo "❌ Environment variable MARIADB_ROOT_PASSWORD is required."
    exit 1
fi

if [ -z "$FRAPPE_ADMIN_PASSWORD" ]; then
    echo "❌ Environment variable FRAPPE_ADMIN_PASSWORD is required."
    exit 1
fi

sync_site_configuration() {
    local site="$1"
    echo "🔐 Syncing site configuration for $site..."
    bench --site "$site" set-admin-password "$FRAPPE_ADMIN_PASSWORD"
    bench --site "$site" set-config developer_mode "$FRAPPE_DEVELOPER_MODE"
    bench --site "$site" set-config mute_emails "$FRAPPE_MUTE_EMAILS"

    if [ -n "$FRAPPE_ENCRYPTION_KEY" ]; then
        bench --site "$site" set-config encryption_key "$FRAPPE_ENCRYPTION_KEY"
    fi

    if [ -n "$FRAPPE_DB_PASSWORD" ]; then
        bench --site "$site" set-config db_password "$FRAPPE_DB_PASSWORD"
    fi

    if [ -n "$FRAPPE_DOMAIN" ]; then
        bench --site "$site" set-config host_name "$FRAPPE_DOMAIN"
    fi

    bench --site "$site" clear-cache
}

echo "=== FRAPPE + MODMOSHE MINIMAL INSTALLATION ==="

# Function to wait for MariaDB
wait_for_mariadb() {
    echo "⏳ Waiting for MariaDB..."
    while ! mysqladmin ping -h mariadb -u root -p"$MARIADB_ROOT_PASSWORD" --silent; do
        sleep 2
    done
    echo "✅ MariaDB is ready!"
}

# Function to wait for Redis
wait_for_redis() {
    echo "⏳ Waiting for Redis..."
    while ! redis-cli -h redis ping > /dev/null 2>&1; do
        sleep 2
    done
    echo "✅ Redis is ready!"
}

# Check if bench exists and has our custom app
if [ -d "/home/frappe/frappe-bench/apps/modmoshe" ] && [ -d "/home/frappe/frappe-bench/sites/$FRAPPE_SITE_NAME" ]; then
    echo "🌐 ModMoshe setup exists, starting services..."
    cd /home/frappe/frappe-bench
    sync_site_configuration "$FRAPPE_SITE_NAME"
    bench use "$FRAPPE_DEFAULT_SITE"
    bench start
    exit 0
fi

echo "🚀 Creating minimal Frappe + ModMoshe installation..."

# Wait for services
wait_for_mariadb
wait_for_redis

# Remove any incomplete bench directory
rm -rf /home/frappe/frappe-bench

# Create bench with only Frappe
echo "📦 Initializing minimal bench..."
bench init --skip-redis-config-generation frappe-bench --version "$FRAPPE_BENCH_VERSION"
cd frappe-bench

# Configure for Docker
echo "🔧 Configuring for Docker environment..."
bench set-mariadb-host mariadb
bench set-redis-cache-host redis://redis:6379
bench set-redis-queue-host redis://redis:6379
bench set-redis-socketio-host redis://redis:6379

# Clean Procfile
sed -i '/redis/d' ./Procfile
sed -i '/watch/d' ./Procfile

# Install custom modmoshe app - create proper symlink approach
echo "📥 Installing ModMoshe (custom app)..."
if [ -d "/workspace/modmoshe" ]; then
    echo "   Creating symlink to modmoshe in apps directory..."
    ln -sf /workspace/modmoshe ./apps/modmoshe
    echo "   Installing modmoshe as editable package..."
    /home/frappe/frappe-bench/env/bin/pip install -e ./apps/modmoshe
    echo "   Adding modmoshe to apps.txt..."
    echo "modmoshe" >> apps.txt
    echo "   Verifying setup..."
    ls -la apps/modmoshe
    cat apps.txt
    echo "   ModMoshe app setup completed!"
else
    echo "   Error: ModMoshe app directory not found at /workspace/modmoshe"
    exit 1
fi

# Create site with minimal apps
echo "🏗️  Creating main site ($FRAPPE_SITE_NAME)..."
bench_new_site_args=(
    "$FRAPPE_SITE_NAME"
    --force
    --mariadb-root-password "$MARIADB_ROOT_PASSWORD"
    --admin-password "$FRAPPE_ADMIN_PASSWORD"
    --no-mariadb-socket
)

if [ -n "$FRAPPE_DB_NAME" ]; then
    bench_new_site_args+=(--db-name "$FRAPPE_DB_NAME")
fi

if [ -n "$FRAPPE_DB_PASSWORD" ]; then
    bench_new_site_args+=(--db-password "$FRAPPE_DB_PASSWORD")
fi

bench new-site "${bench_new_site_args[@]}"

echo "📱 Installing ModMoshe on $FRAPPE_SITE_NAME..."
echo "   Final verification before installation..."
cat apps.txt
ls -la apps/
bench --site "$FRAPPE_SITE_NAME" install-app modmoshe

echo "⚙️  Applying site configuration from environment..."
sync_site_configuration "$FRAPPE_SITE_NAME"

# Set as default site
bench use "$FRAPPE_DEFAULT_SITE"

echo "✅ Minimal installation complete!"
echo "📝 Available apps:"
echo "   - Frappe Desk: /desk"
echo "   - ModMoshe: /apps/modmoshe (custom app)"

echo "✅ Installation complete!"

echo "🚀 Starting Frappe services..."
cd /home/frappe/frappe-bench
bench start
