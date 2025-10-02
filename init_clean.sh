#!/bin/bash

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Cleanup en caso de interrupción
cleanup() {
    warn "Interrupción recibida. Deteniendo..."
    docker compose down
    exit 1
}
trap cleanup SIGINT SIGTERM

# Esperar servicios
wait_for_mariadb() {
    info "Esperando MariaDB..."
    while ! docker compose exec mariadb mysqladmin ping --silent -h localhost -u root -p123 2>/dev/null; do
        echo -n "."
        sleep 2
    done
    echo ""
    info "MariaDB listo ✓"
}

wait_for_redis() {
    info "Esperando Redis..."
    while ! docker compose exec redis redis-cli ping 2>/dev/null | grep -q PONG; do
        echo -n "."
        sleep 2
    done
    echo ""
    info "Redis listo ✓"
}

# Main installation
info "🚀 Iniciando Frappe Builder..."

# Configuración
SITE_NAME="builder.localhost"
ADMIN_PASS="admin"

# Iniciar servicios base
info "Iniciando servicios..."
docker compose up -d mariadb redis

wait_for_mariadb
wait_for_redis

# Iniciar Frappe
docker compose up -d frappe
sleep 10

# Verificar si sitio existe
if docker compose exec frappe bash -c "ls /home/frappe/frappe-bench/sites/$SITE_NAME" 2>/dev/null; then
    info "Sitio existe, omitiendo creación..."
else
    info "Creando sitio $SITE_NAME..."
    docker compose exec frappe bash -c "cd frappe-bench && bench new-site $SITE_NAME --admin-password $ADMIN_PASS --db-root-password 123 --set-default"
fi

# Verificar Builder
if docker compose exec frappe bash -c "ls /home/frappe/frappe-bench/apps/builder" 2>/dev/null; then
    info "Builder existe, verificando instalación..."
    docker compose exec frappe bash -c "cd frappe-bench && bench --site $SITE_NAME install-app builder" 2>/dev/null || true
else
    info "Descargando e instalando Builder..."
    docker compose exec frappe bash -c "cd frappe-bench && bench get-app builder https://github.com/frappe/builder.git"
    docker compose exec frappe bash -c "cd frappe-bench && bench --site $SITE_NAME install-app builder"
fi

# Configurar Redis con URLs correctas
info "Configurando Redis..."
docker compose exec frappe bash -c "cd frappe-bench && bench set-config -g redis_cache 'redis://redis:6379'"
docker compose exec frappe bash -c "cd frappe-bench && bench set-config -g redis_queue 'redis://redis:6379'"
docker compose exec frappe bash -c "cd frappe-bench && bench set-config -g redis_socketio 'redis://redis:6379'"

# Modo desarrollo
docker compose exec frappe bash -c "cd frappe-bench && bench set-config -g developer_mode 1"

# Instalar dependencias Node.js críticas
info "Instalando dependencias Node.js..."
docker compose exec frappe bash -c "cd frappe-bench/apps/frappe && yarn install" 2>/dev/null || true
docker compose exec frappe bash -c "cd frappe-bench/apps/builder && yarn install" 2>/dev/null || true

# Reiniciar y verificar
docker compose restart frappe
sleep 15

info "✅ ¡Instalación completada!"
echo ""
echo "🌐 Acceso:"
echo "   • http://builder.localhost:8000"
echo "   • http://builder.localhost:8000/builder"
echo ""
echo "🔑 Credenciales: Administrator / admin"
echo ""
echo "📊 Logs: docker compose logs -f frappe"