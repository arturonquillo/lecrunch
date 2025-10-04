#!/bin/bash

echo "📦 Creando backup de la base de datos..."

# Crear backup completo con archivos
docker compose exec frappe bash -c "cd /home/frappe/frappe-bench && bench --site localhost backup --with-files"

# Obtener el nombre del backup más reciente
LATEST_SQL=$(docker compose exec frappe bash -c "ls -t /home/frappe/frappe-bench/sites/localhost/private/backups/*database*.sql.gz 2>/dev/null | head -1" | tr -d '\r')
LATEST_FILES=$(docker compose exec frappe bash -c "ls -t /home/frappe/frappe-bench/sites/localhost/private/backups/*files*.tar 2>/dev/null | head -1" | tr -d '\r')

if [ ! -z "$LATEST_SQL" ]; then
    # Copiar backup SQL al host
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    docker compose cp frappe:$LATEST_SQL ./frappe-bench/backups/database_${TIMESTAMP}.sql.gz
    echo "✅ Database backup: frappe-bench/backups/database_${TIMESTAMP}.sql.gz"
fi

if [ ! -z "$LATEST_FILES" ]; then
    # Copiar backup de archivos al host
    docker compose cp frappe:$LATEST_FILES ./frappe-bench/backups/files_${TIMESTAMP}.tar
    echo "✅ Files backup: frappe-bench/backups/files_${TIMESTAMP}.tar"
fi

echo "🎉 Backup completado!"
echo ""
echo "📋 Para versionar este backup:"
echo "   git add frappe-bench/backups/database_${TIMESTAMP}.sql.gz"
echo "   git commit -m '🗄️ Backup con configuración actualizada'"