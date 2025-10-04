# Frappe Builder + - **🛒 Ecommerce Integrations**: 
  - http://localhost:8000/apps/ecommerce_integrations
  - Integraciones de comercio electrónico (Shopify, WooCommerce, etc.)

- **🏪 Webshop**: 
  - http://localhost:8000/apps/webshop
  - Tienda online completa con carrito de compras

- **👨‍💻 Dev Server**: http://localhost:8080
  - Servidor de desarrollo para frontend🌐 Acceso por Subdominios

Una vez completada la instalación, cada aplicación tiene su propio subdominio:

### 🎯 **Acceso por Rutas:**
- **🏠 Frappe Desk**: http://localhost:8000/desk
  - Panel de administración del framework
  - Gestión de usuarios, configuración, etc.
  
- **🔧 Frappe Builder**: 
  - http://localhost:8000/apps/builder
  - http://localhost:8000/builder (acceso directo)
  - Constructor visual de aplicaciones web

- **📊 ERPNext**: 
  - http://localhost:8000/apps/erpnext  
  - http://localhost:8000/app (acceso directo)
  - Sistema completo de gestión empresarial

- **� Ecommerce Integrations**: 
  - http://localhost:8000/apps/ecommerce_integrations
  - Integraciones de comercio electrónico (Shopify, WooCommerce, etc.)

- **�👨‍💻 Dev Server**: http://localhost:8080
  - Servidor de desarrollo para frontend

### 🔑 **Credenciales (para todos los sitios):**
- Usuario: `Administrator`
- Contraseña: `admin`-Subdomain Docker Setup ✨

# Frappe Builder + ERPNext - Docker Setup ✨

¡**FUNCIONA PERFECTAMENTE**! 🎉

Este proyecto implementa **Frappe Framework**, **Frappe Builder**, **ERPNext**, **Ecommerce Integrations** y **Webshop** usando Docker en un solo sitio con múltiples apps accesibles por rutas, basado en los repertorios oficiales de [frappe/builder](https://github.com/frappe/builder), [frappe/erpnext](https://github.com/frappe/erpnext), [frappe/ecommerce_integrations](https://github.com/frappe/ecommerce_integrations) y [frappe/webshop](https://github.com/frappe/webshop).

## 🚀 Instalación Rápida

```bash
# 1. Clonar este repositorio
git clone <este-repo>
cd frape2

# 2. Iniciar (primera vez toma 10-15 minutos)
docker compose up -d

# 3. Monitorear progreso
docker compose logs -f frappe

# 4. Cuando veas "HTTP/1.1" en los logs, ¡está listo!
```

## 🏗️ Arquitectura Estándar de Frappe

Este setup utiliza la configuración estándar de Frappe con **múltiples apps en un solo sitio**:

```
Cliente → localhost:8000
├── /desk                        → Frappe Framework (administración)
├── /apps/builder                → Frappe Builder 
├── /builder                     → Acceso directo a Builder
├── /apps/erpnext                → ERPNext
├── /app                         → Acceso directo a ERPNext
├── /apps/ecommerce_integrations → Ecommerce Integrations
└── /apps/webshop                → Webshop (Tienda online)
```**Ventajas del método estándar:**
- 🎯 **Configuración típica** de Frappe
- 🔒 **Todas las apps en un sitio** 
- 📊 **Datos compartidos** entre aplicaciones
- 🚀 **Más simple** de administrar
- ⚡ **URLs estándar** de Frappe

## 🌐 Acceso

Una vez completada la instalación:

- **🏠 Sitio principal**: http://builder.localhost:8000
- **🔧 Builder interface**: http://builder.localhost:8000/builder
- **� ERPNext**: http://builder.localhost:8000/desk
- **�👨‍💻 Dev server**: http://builder.localhost:8080

**Credenciales:**
- Usuario: `Administrator`
- Contraseña: `admin`

## 🛠️ Comandos Útiles

```bash
# Ver estado
docker compose ps

# Ver logs en tiempo real
docker compose logs -f frappe

# Detener (conserva apps y sitios)
docker compose down

# Reiniciar completamente (conserva apps y sitios)
docker compose down && docker compose up -d

# Eliminar TODO incluyendo volúmenes (CUIDADO: borra desarrollo)
docker compose down -v

# Acceder al contenedor para desarrollo
docker compose exec frappe bash
```

## 🔧 Desarrollo y Personalización

### **📁 Volúmenes Externos Persistentes ✅**
**NUEVA FUNCIONALIDAD:** Todo el desarrollo se conserva como volumen externo:
- `./frappe-bench/` - **Volumen completo persistente** montado desde el host
  - `apps/frappe/` - Framework core (externo)
  - `apps/erpnext/` - ERP application (externo)  
  - `apps/builder/` - Page builder (externo)
  - `apps/ecommerce_integrations/` - E-commerce integrations (externo)
  - `apps/payments/` - Payment processing (externo)
  - `apps/webshop/` - Web store (externo)
  - `apps/custom/` - Tus apps personalizadas (externo)
  - `sites/` - Site configurations (externo)
  - `env/` - Python environment (externo)

**🎯 Beneficios del Volumen Externo:**
- ✅ **Edición directa**: Modifica código en `/Users/moshe/Projects/frape2/frappe-bench/`
- ✅ **Persistencia total**: Cambios sobreviven recreación de contenedores
- ✅ **Version control**: Commit apps y modificaciones personalizadas
- ✅ **Desarrollo ágil**: Sin reinstalaciones entre reinicios

### **Comandos de Desarrollo**
```bash
# Acceder al contenedor
docker compose exec frappe bash

# Una vez dentro del contenedor:
cd /home/frappe/frappe-bench

# Crear nueva app personalizada
bench new-app mi_app_custom

# Instalar app personalizada
bench --site localhost install-app mi_app_custom

# Migrar después de cambios
bench --site localhost migrate

# Reiniciar servicios
bench restart
```

## 📁 Estructura

```
frape2/
├── docker-compose.yml    # Servicios Docker simples
├── init.sh              # Script instalación sitio único con múltiples apps
├── manage.sh            # Comandos útiles
├── status.sh            # Verificar estado
└── README.md           # Este archivo
```

## 🔧 Servicios

- **MariaDB 10.8**: Base de datos con healthcheck
- **Redis Alpine**: Cache y queues con healthcheck  
- **Frappe/Bench**: Contenedor con sitio único:
  - **localhost**: Frappe + Builder + ERPNext + Ecommerce + Webshop

## ⚡ Características Técnicas

- ✅ **Configuración estándar** de Frappe
- ✅ **Múltiples apps en un sitio** 
- ✅ **Rutas estándar** (/apps/builder, /apps/erpnext)
- ✅ **Volúmenes persistentes** para desarrollo
- ✅ **Apps y sitios conservados** entre reinicios
- ✅ **Healthchecks** para todos los servicios
- ✅ **URLs Redis corregidas** (redis://redis:6379)
- ✅ **Dependencias Node.js** instaladas correctamente
- ✅ **Script robusto** con manejo de errores
- ✅ **Acceso unificado** a todas las aplicaciones

## 🐛 Solución de Problemas

Si algo no funciona:

1. Verificar que Docker esté corriendo
2. Verificar que `/etc/hosts` tenga: `127.0.0.1 builder.localhost`
3. Esperar a que aparezcan requests HTTP en los logs
4. Si hay errores, reiniciar: `docker compose down -v && docker compose up -d`

## 🏆 Lo que se solucionó

- ❌ Error "Cannot find module 'socket.io'" → ✅ Dependencias Node.js correctas
- ❌ "Redis URL must specify scheme" → ✅ URLs Redis con redis://
- ❌ Contenedores reiniciándose → ✅ Healthchecks y configuración estable
- ❌ Script colgándose → ✅ Lógica de instalación robusta
- ❌ Solo Frappe Builder → ✅ Builder + ERPNext completamente integrados

---

**¡Disfruta construyendo sitios web increíbles con Frappe Builder!** 🎨✨