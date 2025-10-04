#!/bin/bash

if [ -z "$1" ]; then
    echo "❌ Error: Debes especificar el archivo de backup"
    echo ""
    echo "📋 Uso:"
    echo "   ./restore_db.sh <archivo_backup.sql.gz>"
    echo ""
    echo "📁 Backups disponibles:"
    ls -la frappe-bench/backups/*.sql.gz 2>/dev/null || echo "   No hay backups disponibles"
    exit 1
fi

BACKUP_FILE="$1"

if [ ! -f "$BACKUP_FILE" ]; then
    echo "❌ Error: El archivo $BACKUP_FILE no existe"
    exit 1
fi

echo "🔄 Restaurando backup: $BACKUP_FILE"
echo "⚠️  ADVERTENCIA: Esto sobrescribirá la base de datos actual"
read -p "¿Continuar? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Restauración cancelada"
    exit 1
fi

# Copiar backup al contenedor
BACKUP_BASENAME=$(basename "$BACKUP_FILE")
docker compose cp "$BACKUP_FILE" frappe:/tmp/

# Restaurar base de datos
echo "🔄 Restaurando base de datos..."
docker compose exec frappe bash -c "cd /home/frappe/frappe-bench && bench --site localhost restore /tmp/$BACKUP_BASENAME --force"

# Buscar archivo de files correspondiente
FILES_BACKUP="${BACKUP_FILE%_database_*}_files_${BACKUP_FILE##*_database_}"
FILES_BACKUP="${FILES_BACKUP%.sql.gz}.tar"

if [ -f "$FILES_BACKUP" ]; then
    echo "🔄 Restaurando archivos..."
    FILES_BASENAME=$(basename "$FILES_BACKUP")
    docker compose cp "$FILES_BACKUP" frappe:/tmp/
    docker compose exec frappe bash -c "cd /home/frappe/frappe-bench && bench --site localhost restore /tmp/$FILES_BASENAME --force"
fi

# Limpiar archivos temporales
docker compose exec frappe bash -c "rm -f /tmp/$BACKUP_BASENAME /tmp/$FILES_BASENAME"

echo "✅ Restore completado!"
echo "🌐 Accede a: http://localhost:8000"
echo "👤 Credenciales: Administrator / admin"