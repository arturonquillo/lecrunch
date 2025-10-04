# 🗄️ Sistema de Backups de Base de Datos

Este sistema permite hacer backups completos de la base de datos y archivos de Frappe, y versionarlos en git para colaboración.

## 📦 Crear Backup

```bash
# Crear backup completo (BD + archivos)
./frappe-bench/backup_db.sh
```

Esto genera:
- `database_YYYYMMDD_HHMMSS.sql.gz` - Base de datos completa
- `files_YYYYMMDD_HHMMSS.tar` - Archivos y assets

## 🔄 Restaurar Backup

```bash
# Ver backups disponibles
ls frappe-bench/backups/

# Restaurar un backup específico
./frappe-bench/restore_db.sh frappe-bench/backups/database_20251004_120000.sql.gz
```

## 🌟 Workflow de Desarrollo

### 1. Configurar tu ambiente
```bash
# Acceder a Frappe
open http://localhost:8000

# Hacer cambios:
# - Activar shopping cart
# - Configurar ecommerce
# - Agregar productos
# - Personalizar website
```

### 2. Crear backup de tu configuración
```bash
# Crear backup cuando todo esté listo
./frappe-bench/backup_db.sh
```

### 3. Versionar backup importante
```bash
# Renombrar para identificarlo fácilmente
mv frappe-bench/backups/database_20251004_120000.sql.gz frappe-bench/backups/production_v1.0_shopping_cart.sql.gz

# Versionar
git add frappe-bench/backups/production_v1.0_shopping_cart.sql.gz
git commit -m "🛒 Backup con shopping cart y ecommerce configurado"
git push
```

### 4. Colaboradores pueden usar tu configuración
```bash
# Descargar cambios
git pull

# Usar tu configuración
./frappe-bench/restore_db.sh frappe-bench/backups/production_v1.0_shopping_cart.sql.gz
```

## 📂 Tipos de Backups

### 🎯 Backups para Versionar (Importantes)
```bash
production_v1.0_*.sql.gz     # Versiones de producción
staging_*_*.sql.gz           # Versiones de staging
milestone_*_*.sql.gz         # Hitos importantes
```

### 🚫 Backups NO Versionados (Temporales)
```bash
database_YYYYMMDD_*.sql.gz   # Backups automáticos diarios
dev_*_*.sql.gz              # Backups de desarrollo
test_*_*.sql.gz             # Backups de pruebas
```

## ⚙️ Comandos Útiles

```bash
# Backup rápido con nombre personalizado
./frappe-bench/backup_db.sh && mv frappe-bench/backups/database_*.sql.gz frappe-bench/backups/milestone_shopping_cart.sql.gz

# Ver espacio usado por backups
du -sh frappe-bench/backups/

# Limpiar backups antiguos (mantener solo los importantes)
rm frappe-bench/backups/database_*.sql.gz
```

## 🎯 Ventajas de Esta Estrategia

- ✅ **Simple**: Un comando para backup/restore
- ✅ **Completo**: TODO se respalda (datos, configuración, archivos)
- ✅ **Versionable**: Los backups importantes van al repo
- ✅ **Colaborativo**: El equipo puede compartir configuraciones exactas
- ✅ **Confiable**: Funciona al 100% siempre
- ✅ **Rápido**: Restore en segundos

## 🚀 ¿Listo para Desarrollar?

1. Configura todo en http://localhost:8000
2. Haz backup con `./frappe-bench/backup_db.sh`
3. Versiona con git
4. ¡Tu equipo puede usar exactamente tu misma configuración!

**¡Mucho más simple que fixtures y configuraciones manuales!** 🎉