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
if [ -d "/home/frappe/frappe-bench/apps/frappe" ] && [ -d "/home/frappe/frappe-bench/sites/localhost" ]; then
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
echo "🏗️  Creating main site (localhost)..."
bench new-site localhost \
    --force \
    --mariadb-root-password 123 \
    --admin-password admin \
    --no-mariadb-socket

echo "📱 Installing ERPNext on localhost..."
bench --site localhost install-app erpnext

echo "📱 Installing Builder on localhost..."
bench --site localhost install-app builder

echo "📱 Installing Ecommerce Integrations on localhost..."
bench --site localhost install-app ecommerce_integrations

echo "📱 Installing Payments on localhost..."
bench --site localhost install-app payments

echo "📱 Installing Webshop on localhost..."
bench --site localhost install-app webshop

echo "📱 Installing Frappe CRM on localhost..."
bench --site localhost install-app crm

echo "📱 Installing ModMoshe on localhost..."
if [ -d "/workspace/modmoshe" ] && [ -d "./apps/modmoshe" ]; then
    # Create sites/apps.txt with all apps properly separated
    echo -e "frappe\nerpnext\nbuilder\necommerce_integrations\npayments\nwebshop\ncrm\nmodmoshe" > sites/apps.txt
    bench --site localhost install-app modmoshe --force
    echo "✅ ModMoshe installed successfully!"
else
    echo "⚠️  ModMoshe not prepared - skipping installation"
fi

echo "⚙️  Configuring site for development..."
bench --site localhost set-config developer_mode 1
bench --site localhost set-config mute_emails 1
bench --site localhost clear-cache

# Set as default site
bench use localhost

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

echo "🚀 Starting Frappe services..."
cd /home/frappe/frappe-bench
bench start