#!/bin/bash

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE_PATH=${ENV_FILE_PATH:-"$SCRIPT_DIR/.env"}

if [ -f "$ENV_FILE_PATH" ]; then
    set -a
    # shellcheck disable=SC1090
    . "$ENV_FILE_PATH"
    set +a
else
    warn "Archivo de entorno no encontrado en: $ENV_FILE_PATH (usa ENV_FILE_PATH=/ruta/.env)"
fi

SITE_NAME=${FRAPPE_SITE_NAME:-builder.localhost}
ADMIN_PASS=${FRAPPE_ADMIN_PASSWORD:-}
DB_ROOT_PASS=${MARIADB_ROOT_PASSWORD:-}
DEFAULT_SITE=${FRAPPE_DEFAULT_SITE:-$SITE_NAME}
DEVELOPER_MODE=${FRAPPE_DEVELOPER_MODE:-1}
MUTE_EMAILS=${FRAPPE_MUTE_EMAILS:-1}
ADMIN_EMAIL=${FRAPPE_ADMIN_EMAIL:-}
ENCRYPTION_KEY=${FRAPPE_ENCRYPTION_KEY:-}
DB_PASSWORD=${FRAPPE_DB_PASSWORD:-}
SITE_DOMAIN=${FRAPPE_DOMAIN:-}

# Cleanup en caso de interrupción
cleanup() {
    warn "Interrupción recibida. Deteniendo..."
    docker compose down
    exit 1
}
trap cleanup SIGINT SIGTERM

# Esperar servicios
wait_for_mariadb() {
    if [ -z "$DB_ROOT_PASS" ]; then
        error "Variable MARIADB_ROOT_PASSWORD no configurada. Revise su archivo .env."
        exit 1
    fi
    info "Esperando MariaDB..."
    while ! docker compose exec mariadb mysqladmin ping --silent -h localhost -u root -p"$DB_ROOT_PASS" 2>/dev/null; do
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

apply_site_configuration() {
    info "Sincronizando configuración del sitio $SITE_NAME según .env..."
    docker compose exec \
        --env BENCH_SITE="$SITE_NAME" \
        --env BENCH_ADMIN_PASSWORD="$ADMIN_PASS" \
        frappe bash -lc 'cd frappe-bench && bench --site "$BENCH_SITE" set-admin-password "$BENCH_ADMIN_PASSWORD"'

    docker compose exec frappe bash -c "cd frappe-bench && bench --site $SITE_NAME set-config developer_mode $DEVELOPER_MODE"
    docker compose exec frappe bash -c "cd frappe-bench && bench --site $SITE_NAME set-config mute_emails $MUTE_EMAILS"

    if [ -n "$ADMIN_EMAIL" ]; then
        docker compose exec \
            --env BENCH_SITE="$SITE_NAME" \
            --env BENCH_ADMIN_EMAIL="$ADMIN_EMAIL" \
            frappe bash -lc 'cd frappe-bench && bench --site "$BENCH_SITE" set-config admin_email "$BENCH_ADMIN_EMAIL"'
    fi

    if [ -n "$ENCRYPTION_KEY" ]; then
        docker compose exec \
            --env BENCH_SITE="$SITE_NAME" \
            --env BENCH_ENCRYPTION_KEY="$ENCRYPTION_KEY" \
            frappe bash -lc 'cd frappe-bench && bench --site "$BENCH_SITE" set-config encryption_key "$BENCH_ENCRYPTION_KEY"'
    fi

    if [ -n "$DB_PASSWORD" ]; then
        docker compose exec \
            --env BENCH_SITE="$SITE_NAME" \
            --env BENCH_DB_PASSWORD="$DB_PASSWORD" \
            frappe bash -lc 'cd frappe-bench && bench --site "$BENCH_SITE" set-config db_password "$BENCH_DB_PASSWORD"'
    fi

    if [ -n "$SITE_DOMAIN" ]; then
        docker compose exec \
            --env BENCH_SITE="$SITE_NAME" \
            --env BENCH_HOST_NAME="$SITE_DOMAIN" \
            frappe bash -lc 'cd frappe-bench && bench --site "$BENCH_SITE" set-config host_name "$BENCH_HOST_NAME"'
    fi

    docker compose exec frappe bash -c "cd frappe-bench && bench --site $SITE_NAME clear-cache"
    docker compose exec frappe bash -c "cd frappe-bench && bench use $DEFAULT_SITE"
}

# Main installation
info "🚀 Iniciando Frappe Builder..."

# Validaciones de configuración
if [ -z "$ADMIN_PASS" ]; then
    error "Variable FRAPPE_ADMIN_PASSWORD no configurada. Revise su archivo .env."
    exit 1
fi

if [ -z "$SITE_NAME" ]; then
    error "Variable FRAPPE_SITE_NAME no configurada. Revise su archivo .env."
    exit 1
fi

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
    docker compose exec \
        --env BENCH_SITE="$SITE_NAME" \
        --env BENCH_ADMIN_PASSWORD="$ADMIN_PASS" \
        --env BENCH_DB_ROOT_PASSWORD="$DB_ROOT_PASS" \
        frappe bash -lc 'cd frappe-bench && bench new-site "$BENCH_SITE" --admin-password "$BENCH_ADMIN_PASSWORD" --mariadb-root-password "$BENCH_DB_ROOT_PASSWORD" --set-default'
fi

apply_site_configuration

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

# Modo desarrollo (global)
docker compose exec frappe bash -c "cd frappe-bench && bench set-config -g developer_mode $DEVELOPER_MODE"
docker compose exec frappe bash -c "cd frappe-bench && bench set-config -g mute_emails $MUTE_EMAILS"

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
echo "   • http://$SITE_NAME:8000"
echo "   • http://$SITE_NAME:8000/builder"
echo ""
echo "🔑 Credenciales: Administrator / (consultar FRAPPE_ADMIN_PASSWORD en .env)"
echo ""
echo "📊 Logs: docker compose logs -f frappe"
