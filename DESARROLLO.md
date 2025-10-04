# 🚀 Guía de Desarrollo con Volúmenes Persistentes

## ✅ Setup Completado

Este proyecto ya tiene configurados **volúmenes persistentes** para desarrollo. Todos tus cambios se guardan y pueden ser versionados.

## 📁 Estructura Versionada

```
frape2/
├── frappe-bench/                    # Volumen persistente
│   ├── apps/custom/                 # ✅ TUS APPS PERSONALIZADAS (versionadas)
│   ├── sites/apps.txt              # ✅ Configuración de apps (versionada)
│   ├── sites/common_site_config.json # ✅ Config del sitio (versionada)
│   └── Procfile                    # ✅ Configuración de procesos (versionada)
└── docker-compose.yml              # ✅ Setup completo con volumen
```

## 🛠️ Flujo de Desarrollo

### 1. Crear App Personalizada

```bash
# Acceder al contenedor
docker compose exec frappe bash

# Ir al bench
cd /home/frappe/frappe-bench

# Crear nueva app
bench new-app mi_app_increible

# Mover a directorio versionado
mv apps/mi_app_increible apps/custom/

# Instalar en el sitio
bench --site localhost install-app mi_app_increible
```

### 2. Desarrollar y Versionar

```bash
# Tus cambios en apps/custom/ se versioñan automáticamente
git add frappe-bench/apps/custom/mi_app_increible/
git commit -m "✨ Nueva funcionalidad en mi app"
git push
```

### 3. Reiniciar Preservando Cambios

```bash
# Los cambios persisten entre reinicios
docker compose down
docker compose up -d

# Tu app personalizada sigue ahí y funcionando! 🎉
```

## 🌐 URLs de Acceso

- **🏠 Frappe Desk**: http://localhost:8000/desk
- **🏗️ Builder**: http://localhost:8000/apps/builder  
- **📊 ERPNext**: http://localhost:8000/apps/erpnext
- **🛒 Ecommerce**: http://localhost:8000/apps/ecommerce_integrations

**Credenciales:** `Administrator` / `admin`

## 🔄 Comandos Útiles

```bash
# Ver apps instaladas
docker compose exec frappe bash -c "cd /home/frappe/frappe-bench && bench --site localhost list-apps"

# Reinstalar assets después de cambios
docker compose exec frappe bash -c "cd /home/frappe/frappe-bench && bench build"

# Migrar después de cambios en DocTypes
docker compose exec frappe bash -c "cd /home/frappe/frappe-bench && bench --site localhost migrate"

# Reiniciar servicios
docker compose restart frappe
```

## 🎯 Beneficios del Setup

- ✅ **Desarrollo persistente**: Cambios sobreviven reinicios de contenedor
- ✅ **Versionado inteligente**: Solo tu código personalizado va al repo
- ✅ **Colaboración**: El equipo puede trabajar en las mismas apps personalizadas  
- ✅ **Deploy simple**: El setup funciona en cualquier máquina con Docker
- ✅ **Performance**: Assets compilados, estilos funcionando correctamente

## 🗄️ Sistema de Backups (NUEVO)

### **Workflow Super Simple para Versionar Configuraciones:**

```bash
# 1. Configurar todo en el admin panel
open http://localhost:8000
# - Activar shopping cart
# - Configurar ecommerce  
# - Personalizar website

# 2. Crear backup cuando esté listo
./frappe-bench/backup_db.sh

# 3. Versionar backup importante
mv frappe-bench/backups/database_*.sql.gz frappe-bench/backups/production_v1.0_shopping_cart.sql.gz
git add frappe-bench/backups/production_v1.0_shopping_cart.sql.gz
git commit -m "🛒 Backup con shopping cart configurado"

# 4. Colaboradores pueden usar tu configuración exacta
git pull
./frappe-bench/restore_db.sh frappe-bench/backups/production_v1.0_shopping_cart.sql.gz
```

### **¿Por qué Backups en lugar de Fixtures?**
- ✅ **Súper simple**: Un comando vs configuración compleja
- ✅ **100% completo**: TODA la configuración se respalda  
- ✅ **Confiable**: Funciona siempre
- ✅ **Colaborativo**: El equipo usa exactamente tu misma configuración

📖 **Documentación completa:** `frappe-bench/backups/README.md`

**¡A desarrollar se ha dicho!** 🚀✨