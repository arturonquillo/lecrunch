#!/bin/bash

set -e

echo "=== FRAPPE BUILDER STARTUP SCRIPT ==="

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

# Wait for services
wait_for_mariadb
wait_for_redis

cd /home/frappe/frappe-bench

# Ensure apps are properly installed in the Python environment
echo "🔧 Installing Python packages for all apps..."
for app in apps/*/; do
    if [ -f "$app/setup.py" ] || [ -f "$app/pyproject.toml" ]; then
        app_name=$(basename "$app")
        echo "📦 Installing $app_name..."
        env/bin/python -m pip install --quiet --upgrade -e "$app" || echo "⚠️  Warning: Could not install $app_name"
    fi
done

# Configure bench for Docker if not already configured
if ! grep -q "mariadb" sites/common_site_config.json 2>/dev/null; then
    echo "🔧 Configuring bench for Docker environment..."
    bench set-mariadb-host mariadb
    bench set-redis-cache-host redis://redis:6379
    bench set-redis-queue-host redis://redis:6379
    bench set-redis-socketio-host redis://redis:6379
fi

# Create site if it doesn't exist
if [ ! -d "sites/localhost" ]; then
    echo "🏗️  Creating localhost site..."
    bench new-site localhost \
        --force \
        --mariadb-root-password 123 \
        --admin-password admin \
        --no-mariadb-socket

    echo "📱 Installing apps on localhost..."
    bench --site localhost install-app erpnext --force
    bench --site localhost install-app builder --force
    bench --site localhost install-app ecommerce_integrations --force
    bench --site localhost install-app payments --force
    # Skip webshop for now - install manually later if needed

    echo "⚙️  Configuring site..."
    bench --site localhost set-config developer_mode 1
    bench --site localhost set-config mute_emails 1
    bench --site localhost clear-cache

    # Set as default site
    bench use localhost
else
    echo "✅ Site localhost already exists"
fi

echo "✅ Setup complete! Available at:"
echo "   - Frappe Desk: http://localhost:8000/desk"
echo "   - Builder: http://localhost:8000/apps/builder"
echo "   - ERPNext: http://localhost:8000/apps/erpnext"
echo "   - Webshop: http://localhost:8000/apps/webshop"

echo "🚀 Starting Frappe services..."
bench start