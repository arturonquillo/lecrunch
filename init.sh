#!/bin/bash

set -euo pipefail

MARIADB_ROOT_PASSWORD=${MARIADB_ROOT_PASSWORD:-}
FRAPPE_ADMIN_PASSWORD=${FRAPPE_ADMIN_PASSWORD:-}
FRAPPE_SITE_NAME=${FRAPPE_SITE_NAME:-localhost}
FRAPPE_DEFAULT_SITE=${FRAPPE_DEFAULT_SITE:-$FRAPPE_SITE_NAME}
FRAPPE_DEVELOPER_MODE=${FRAPPE_DEVELOPER_MODE:-1}
FRAPPE_MUTE_EMAILS=${FRAPPE_MUTE_EMAILS:-1}
FRAPPE_ADMIN_EMAIL=${FRAPPE_ADMIN_EMAIL:-}
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

    if [ -n "$FRAPPE_ADMIN_EMAIL" ]; then
        bench --site "$site" set-config admin_email "$FRAPPE_ADMIN_EMAIL"
    fi

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

echo "=== FRAPPE BUILDER INSTALLATION SCRIPT ==="

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

# Check if bench is properly initialized
if [ -d "/home/frappe/frappe-bench/apps/frappe" ] && [ -d "/home/frappe/frappe-bench/sites/$FRAPPE_SITE_NAME" ]; then
    echo "🌐 Complete setup exists, starting services..."
    cd /home/frappe/frappe-bench
    sync_site_configuration "$FRAPPE_SITE_NAME"
    bench use "$FRAPPE_DEFAULT_SITE"
    bench start
    exit 0
fi

echo "🚀 Creating new bench installation..."

# Wait for services
wait_for_mariadb
wait_for_redis

# Remove any incomplete bench directory
rm -rf /home/frappe/frappe-bench

# Create bench
echo "📦 Initializing bench..."
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

# Install Node dependencies for Frappe
echo "📦 Installing Node.js dependencies for Frappe..."
cd apps/frappe
yarn install --network-timeout "$YARN_NETWORK_TIMEOUT"
cd ../..

# Install ERPNext
echo "📥 Getting ERPNext..."
bench get-app erpnext --branch version-15

# Install Builder
echo "📥 Getting Frappe Builder..."
bench get-app builder --branch develop

# Install Ecommerce Integrations
echo "📥 Getting Ecommerce Integrations..."
bench get-app ecommerce_integrations

# Install Payments (dependency for webshop)
echo "📥 Getting Payments..."
bench get-app payments

# Install Webshop
echo "📥 Getting Webshop..."
bench get-app webshop

# Install Frappe CRM
echo "📥 Getting Frappe CRM..."
bench get-app crm --branch main

# Install ModMoshe manually (simple approach)
echo "📱 Installing ModMoshe app..."
if [ -d "/workspace/modmoshe" ]; then
    echo "   Copying ModMoshe app..."
    cp -r /workspace/modmoshe ./apps/modmoshe
    
    echo "   Installing Python package..."
    ./env/bin/pip install -e ./apps/modmoshe
    
    echo "   Adding to apps.txt..."
    echo "modmoshe" >> apps.txt
    
    echo "✅ ModMoshe installed successfully!"
else
    echo "⚠️  ModMoshe directory not found at /workspace/modmoshe - skipping installation"
fi

# Create single site with all apps
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

echo "📱 Installing ERPNext on $FRAPPE_SITE_NAME..."
bench --site "$FRAPPE_SITE_NAME" install-app erpnext

echo "📱 Installing Builder on $FRAPPE_SITE_NAME..."
bench --site "$FRAPPE_SITE_NAME" install-app builder

echo "📱 Installing Ecommerce Integrations on $FRAPPE_SITE_NAME..."
bench --site "$FRAPPE_SITE_NAME" install-app ecommerce_integrations

echo "📱 Installing Payments on $FRAPPE_SITE_NAME..."
bench --site "$FRAPPE_SITE_NAME" install-app payments

echo "📱 Installing Webshop on $FRAPPE_SITE_NAME..."
bench --site "$FRAPPE_SITE_NAME" install-app webshop

echo "📱 Installing Frappe CRM on $FRAPPE_SITE_NAME..."
bench --site "$FRAPPE_SITE_NAME" install-app crm

echo "📱 Installing ModMoshe on $FRAPPE_SITE_NAME..."
if [ -d "/workspace/modmoshe" ] && [ -d "./apps/modmoshe" ]; then
    # Create sites/apps.txt with all apps properly separated
    cat <<'EOF' > sites/apps.txt
frappe
erpnext
builder
ecommerce_integrations
payments
webshop
crm
modmoshe
EOF
    bench --site "$FRAPPE_SITE_NAME" install-app modmoshe --force
    echo "✅ ModMoshe installed successfully!"
else
    echo "⚠️  ModMoshe not prepared - skipping installation"
fi

echo "⚙️  Applying site configuration from environment..."
sync_site_configuration "$FRAPPE_SITE_NAME"

# Set as default site
bench use "$FRAPPE_DEFAULT_SITE"

echo "✅ Single site configuration complete!"
echo "📝 Available apps:"
echo "   - Frappe Desk: /desk"
echo "   - Builder: /apps/builder or /builder"  
echo "   - ERPNext: /apps/erpnext or /app"
echo "   - Frappe CRM: /crm"
echo "   - Ecommerce Integrations: /apps/ecommerce_integrations"
echo "   - Payments: /apps/payments"
echo "   - Webshop: /apps/webshop"
echo "   - ModMoshe: /apps/modmoshe (custom app)"

echo "✅ Installation complete!"

if [ -n "$FRAPPE_ENCRYPTION_KEY" ]; then
    echo "🔐 Custom encryption key applied from environment."
fi

echo "🚀 Starting Frappe services..."
cd /home/frappe/frappe-bench
bench start
