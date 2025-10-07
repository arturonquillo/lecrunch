#!/bin/bash

set -e

echo "=== FRAPPE + MODMOSHE MINIMAL INSTALLATION ==="

# Function to wait for MariaDB
wait_for_mariadb() {
    echo "⏳ Waiting for MariaDB..."
    while ! mysqladmin ping -h mariadb -u root -p123 --silent; do
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
if [ -d "/home/frappe/frappe-bench/apps/modmoshe" ] && [ -d "/home/frappe/frappe-bench/sites/localhost" ]; then
    echo "🌐 ModMoshe setup exists, starting services..."
    cd /home/frappe/frappe-bench
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
bench init --skip-redis-config-generation frappe-bench --version version-15
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
echo "🏗️  Creating main site (localhost)..."
bench new-site localhost \
    --force \
    --mariadb-root-password 123 \
    --admin-password admin \
    --no-mariadb-socket

echo "📱 Installing ModMoshe on localhost..."
echo "   Final verification before installation..."
cat apps.txt
ls -la apps/
bench --site localhost install-app modmoshe

echo "⚙️  Configuring site for development..."
bench --site localhost set-config developer_mode 1
bench --site localhost set-config mute_emails 1
bench --site localhost clear-cache

# Set as default site
bench use localhost

echo "✅ Minimal installation complete!"
echo "📝 Available apps:"
echo "   - Frappe Desk: /desk"
echo "   - ModMoshe: /apps/modmoshe (custom app)"

echo "✅ Installation complete!"

echo "🚀 Starting Frappe services..."
cd /home/frappe/frappe-bench
bench start