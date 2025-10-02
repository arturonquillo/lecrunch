#!/bin/bash

# Frappe Builder Setup Status Checker

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
cd /Users/moshe/Projects/frape2

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
echo "🌐 Sitio principal: http://builder.localhost:8000"
echo "🔧 Builder interface: http://builder.localhost:8000/builder"
echo "👨‍💻 Dev server: http://builder.localhost:8080"
echo
echo "👤 Credenciales: Administrator / admin"
echo
echo "Para monitorear el progreso en tiempo real:"
echo "docker compose logs -f frappe"