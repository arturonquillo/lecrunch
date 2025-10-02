#!/bin/bash

set -e

echo "=== FRAPPE BUILDER INSTALLATION SCRIPT ==="

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

# Check if bench is properly initialized
if [ -d "/home/frappe/frappe-bench/apps/frappe" ] && [ -d "/home/frappe/frappe-bench/sites/builder.localhost" ]; then
    echo "🌐 Complete setup exists, starting services..."
    cd /home/frappe/frappe-bench
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

# Install Node dependencies for Frappe
echo "📦 Installing Node.js dependencies for Frappe..."
cd apps/frappe
yarn install --network-timeout 100000
cd ../..

# Install ERPNext
echo "📥 Getting ERPNext..."
bench get-app erpnext --branch version-15

# Install Builder
echo "📥 Getting Frappe Builder..."
bench get-app builder --branch develop

# Create site
echo "🏗️  Creating site builder.localhost..."
bench new-site builder.localhost \
    --force \
    --mariadb-root-password 123 \
    --admin-password admin \
    --no-mariadb-socket

echo "📱 Installing ERPNext..."
bench --site builder.localhost install-app erpnext

echo "📱 Installing Builder app..."
bench --site builder.localhost install-app builder

echo "⚙️  Configuring site..."
bench --site builder.localhost set-config developer_mode 1
bench --site builder.localhost set-config mute_emails 1
bench --site builder.localhost clear-cache
bench use builder.localhost

echo "✅ Installation complete!"

echo "🚀 Starting Frappe services..."
cd /home/frappe/frappe-bench
bench start