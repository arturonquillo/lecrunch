#!/bin/bash

# Frappe Builder Setup Status Checker

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE_PATH=${ENV_FILE_PATH:-"$SCRIPT_DIR/.env"}

if [ -f "$ENV_FILE_PATH" ]; then
    set -a
    # shellcheck disable=SC1090
    . "$ENV_FILE_PATH"
    set +a
fi

SITE_NAME=${FRAPPE_SITE_NAME:-builder.localhost}

echo "============================================"
echo "    FRAPPE BUILDER - ESTADO DE INSTALACIÓN"
echo "============================================"
echo

# Check Docker
if docker --version &> /dev/null; then
    echo "✅ Docker está disponible"
else
    echo "❌ Docker no está disponible"
    exit 1
fi

# Check if containers are running
cd "$SCRIPT_DIR"

echo
echo "Estado de los contenedores:"
echo "─────────────────────────────"
docker compose ps

echo
echo "Últimas líneas de log de Frappe:"
echo "─────────────────────────────────────────"
docker compose logs --tail=10 frappe

echo
echo "URLs para acceder (cuando esté listo):"
echo "─────────────────────────────────────────"
echo "🌐 Sitio principal: http://$SITE_NAME:8000"
echo "🔧 Builder interface: http://$SITE_NAME:8000/builder"
echo "👨‍💻 Dev server: http://$SITE_NAME:8080"
echo
echo "👤 Credenciales: Administrator / (ver FRAPPE_ADMIN_PASSWORD en .env)"
echo
echo "Para monitorear el progreso en tiempo real:"
echo "docker compose logs -f frappe"
