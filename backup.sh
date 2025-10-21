#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE_PATH=${ENV_FILE_PATH:-"$SCRIPT_DIR/.env"}

if [ -f "$ENV_FILE_PATH" ]; then
    set -a
    # shellcheck disable=SC1090
    . "$ENV_FILE_PATH"
    set +a
fi

SITE_NAME=${FRAPPE_SITE_NAME:-}
BACKUP_ROOT=${BACKUP_ROOT:-"$SCRIPT_DIR/backups"}
DB_ROOT_PASSWORD=${MARIADB_ROOT_PASSWORD:-}
ADMIN_PASSWORD=${FRAPPE_ADMIN_PASSWORD:-}

if [ -z "${SITE_NAME}" ]; then
    echo "❌ FRAPPE_SITE_NAME no está definido. Configura tu archivo .env."
    exit 1
fi

compose_exec() {
    docker compose exec "$@"
}

compose_cp() {
    docker compose cp "$@"
}

ensure_frappe_running() {
    if ! docker compose ps --services --filter "status=running" | grep -qx "frappe"; then
        echo "❌ El contenedor 'frappe' no está en ejecución. Inicia los servicios con 'docker compose up -d'."
        exit 1
    fi
}

list_backups() {
    if [ ! -d "$BACKUP_ROOT" ]; then
        echo "ℹ️  No hay respaldos en $BACKUP_ROOT"
        return
    fi

    shopt -s nullglob
    local backups=("$BACKUP_ROOT"/*)
    shopt -u nullglob

    if [ "${#backups[@]}" -eq 0 ]; then
        echo "ℹ️  No hay respaldos en $BACKUP_ROOT"
        return
    fi

    echo "📦 Respaldos disponibles en $BACKUP_ROOT:"
    for path in "${backups[@]}"; do
        if [ -d "$path" ]; then
            echo " - $(basename "$path")"
        fi
    done
}

create_backup() {
    ensure_frappe_running
    local timestamp
    timestamp="$(date +%Y%m%d_%H%M%S)"
    local tmp_path="/home/frappe/frappe-bench/sites/backups/$timestamp"
    local dest_path="$BACKUP_ROOT/$timestamp"

    echo "🚀 Creando respaldo para el sitio $SITE_NAME..."
    compose_exec frappe bash -lc "mkdir -p '$tmp_path'"
    compose_exec frappe bash -lc "cd frappe-bench && bench --site '$SITE_NAME' backup --backup-path '$tmp_path'"

    mkdir -p "$dest_path"
    compose_cp "frappe:$tmp_path/." "$dest_path"
    compose_exec frappe bash -lc "rm -rf '$tmp_path'"

    echo "✅ Respaldo guardado en: $dest_path"
}

restore_backup() {
    ensure_frappe_running
    local backup_id="${1:-}"

    if [ -z "$backup_id" ]; then
        echo "❌ Debes indicar el identificador del respaldo."
        echo "   Ejemplo: $0 restore 20240212_153000"
        echo
        list_backups
        exit 1
    fi

    local source_path="$BACKUP_ROOT/$backup_id"
    if [ ! -d "$source_path" ]; then
        echo "❌ No existe el respaldo: $source_path"
        exit 1
    fi

    local db_file=""
    local public_files=""
    local private_files=""

    for f in "$source_path"/*-database.sql.gz; do
        if [ -e "$f" ]; then
            db_file="$f"
            break
        fi
    done

    for f in "$source_path"/*-files.tar; do
        if [ -e "$f" ]; then
            public_files="$f"
            break
        fi
    done

    for f in "$source_path"/*-private-files.tar; do
        if [ -e "$f" ]; then
            private_files="$f"
            break
        fi
    done

    if [ -z "$db_file" ] || [ -z "$public_files" ] || [ -z "$private_files" ]; then
        echo "❌ Respaldo incompleto. Se requieren archivos database.sql.gz, files.tar y private-files.tar."
        exit 1
    fi

    echo "⚠️  Se restaurará el sitio $SITE_NAME desde el respaldo $backup_id."
    read -r -p "¿Deseas continuar? (y/N): " confirmation
    echo
    if [[ ! "$confirmation" =~ ^[Yy]$ ]]; then
        echo "ℹ️  Restauración cancelada."
        exit 0
    fi

    local restore_path="/home/frappe/frappe-bench/sites/backups/restore-${backup_id}"
    compose_exec frappe bash -lc "rm -rf '$restore_path' && mkdir -p '$restore_path'"

    compose_cp "$db_file" "frappe:$restore_path/"
    compose_cp "$public_files" "frappe:$restore_path/"
    compose_cp "$private_files" "frappe:$restore_path/"

    local db_basename
    db_basename="$(basename "$db_file")"
    local public_basename
    public_basename="$(basename "$public_files")"
    local private_basename
    private_basename="$(basename "$private_files")"

    echo "🛠️  Restaurando datos..."
    compose_exec frappe bash -lc "cd frappe-bench && bench --site '$SITE_NAME' --force restore '$restore_path/$db_basename' --with-public-files '$restore_path/$public_basename' --with-private-files '$restore_path/$private_basename'"

    if [ -n "$ADMIN_PASSWORD" ]; then
        compose_exec frappe bash -lc "cd frappe-bench && bench --site '$SITE_NAME' set-admin-password '$ADMIN_PASSWORD'"
    fi

    compose_exec frappe bash -lc "rm -rf '$restore_path'"
    echo "✅ Restauración completada. Reinicia servicios si es necesario."
}

show_usage() {
    cat <<EOF
Uso: $0 <comando>

Comandos disponibles:
  create            Crea un respaldo nuevo (base de datos + archivos)
  list              Lista los respaldos disponibles en $BACKUP_ROOT
  restore <id>      Restaura el respaldo indicado (ej: $0 restore 20240212_153000)
  help              Muestra esta ayuda

Variables opcionales:
  ENV_FILE_PATH     Ruta a un .env alternativo (por defecto $SCRIPT_DIR/.env)
  BACKUP_ROOT       Carpeta local donde guardar respaldos (por defecto $BACKUP_ROOT)
EOF
}

case "${1:-help}" in
    create)
        create_backup
        ;;
    list)
        list_backups
        ;;
    restore)
        restore_backup "${2:-}"
        ;;
    help|*)
        show_usage
        ;;
esac
