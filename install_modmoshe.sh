#!/bin/bash

echo "=== INSTALLING MODMOSHE APP ==="

# Wait for Frappe to be ready
echo "⏳ Waiting for Frappe to be ready..."
while ! curl -s http://localhost:8000 > /dev/null; do
    sleep 5
    echo "   Still waiting for Frappe..."
done
echo "✅ Frappe is ready!"

# Go to bench directory
cd /home/frappe/frappe-bench

# Install ModMoshe app properly
echo "📥 Installing ModMoshe app..."

# Method: Direct copy (symlink causes Python import issues)
if [ -d "/workspace/modmoshe" ]; then
    echo "   Removing any existing modmoshe installation..."
    rm -rf ./apps/modmoshe
    ./env/bin/pip uninstall modmoshe -y 2>/dev/null || true
    
    echo "   Copying modmoshe directory..."
    cp -r /workspace/modmoshe ./apps/modmoshe
    
    echo "   Installing Python package..."
    ./env/bin/pip install -e ./apps/modmoshe
    
    echo "   Adding to sites/apps.txt..."
    if [ ! -f "sites/apps.txt" ]; then
        # Create sites/apps.txt if it doesn't exist
        bench list-apps > sites/apps.txt 2>/dev/null || echo "frappe" > sites/apps.txt
    fi
    if ! grep -q "modmoshe" sites/apps.txt; then
        echo "modmoshe" >> sites/apps.txt
    fi
    echo "   Current sites/apps.txt content:"
    cat sites/apps.txt
    
    echo "   Installing on site..."
    bench --site localhost install-app modmoshe --force
    
    echo "✅ ModMoshe installed successfully!"
else
    echo "❌ ModMoshe directory not found at /workspace/modmoshe"
    exit 1
fi