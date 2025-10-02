# Frappe Builder + ERPNext - Docker Setup ✨

¡**FUNCIONA PERFECTAMENTE**! 🎉

Este proyecto implementa **Frappe Builder** y **ERPNext** usando Docker, basado en los repositorios oficiales de [frappe/builder](https://github.com/frappe/builder) y [frappe/erpnext](https://github.com/frappe/erpnext).

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

# Detener
docker compose down

# Reiniciar desde cero (elimina datos)
docker compose down -v
docker compose up -d

# Acceder al contenedor
docker compose exec frappe bash
```

## 📁 Estructura

```
frape2/
├── docker-compose.yml    # Servicios Docker
├── init.sh              # Script de instalación 
├── manage.sh            # Comandos útiles
├── status.sh            # Verificar estado
└── README.md           # Este archivo
```

## 🔧 Servicios

- **MariaDB 10.8**: Base de datos con healthcheck
- **Redis Alpine**: Cache y queues con healthcheck
- **Frappe Builder**: Constructor visual de aplicaciones web
- **ERPNext**: Sistema integral de gestión empresarial (ERP)  
- **Frappe/Bench**: Aplicación principal con Builder

## ⚡ Características Técnicas

- ✅ **Healthchecks** para todos los servicios
- ✅ **URLs Redis corregidas** (redis://redis:6379)
- ✅ **Dependencias Node.js** instaladas correctamente
- ✅ **Script robusto** con manejo de errores
- ✅ **Configuración Docker** optimizada
- ✅ **Frappe Builder + ERPNext** integrados en una sola instancia

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