# Troubleshooting Guide - Frappe Builder Docker

## Problemas Comunes y Soluciones

### 1. El contenedor de Frappe se reinicia constantemente

**Síntomas:**
- `docker compose ps` muestra el contenedor frappe reiniciándose
- Los logs muestran errores de conexión a la base de datos

**Solución:**
```bash
# Esperar más tiempo - la primera inicialización puede tomar 15+ minutos
docker compose logs -f frappe

# Si persiste, reiniciar todo
docker compose down
docker compose up -d
```

### 2. Error "Database not found" o "Connection refused"

**Causa:** MariaDB aún no ha terminado de inicializarse

**Solución:**
```bash
# Verificar que MariaDB esté corriendo
docker compose ps mariadb

# Ver logs de MariaDB
docker compose logs mariadb

# Esperar hasta ver: "ready for connections"
# Luego reiniciar frappe
docker compose restart frappe
```

### 3. Puerto 8000 ya está en uso

**Error:** `bind: address already in use`

**Solución:**
Editar `docker-compose.yml` y cambiar los puertos:
```yaml
ports:
  - "8001:8000"  # Cambiar puerto externo
  - "9001:9000"
  - "8081:8080"
```

### 4. La instalación se cuelga en "Installing frappe"

**Síntomas:**
- Los logs se detienen en "Installing frappe"
- No hay progreso por más de 20 minutos

**Solución:**
```bash
# Aumentar memoria disponible para Docker (min 4GB recomendado)
# Luego reiniciar
docker compose down
docker compose up -d
```

### 5. Error "bench: command not found"

**Causa:** Intentas usar bench fuera del contenedor

**Solución:**
```bash
# Usar el script de gestión
./manage.sh bench

# O acceder directamente al contenedor
docker compose exec frappe bash
cd frappe-bench
```

### 6. No puedo acceder a builder.localhost

**Solución 1 - Agregar al hosts:**
```bash
# macOS/Linux
sudo echo "127.0.0.1 builder.localhost" >> /etc/hosts

# Windows
# Editar C:\Windows\System32\drivers\etc\hosts
# Agregar: 127.0.0.1 builder.localhost
```

**Solución 2 - Usar localhost:**
- `http://localhost:8000` (en lugar de builder.localhost:8000)

### 7. El frontend (puerto 8080) no funciona

**Causa:** El servidor de desarrollo frontend no está corriendo

**Solución:**
```bash
# Acceder al contenedor
docker compose exec frappe bash

# Ir al directorio frontend
cd frappe-bench/apps/builder/frontend

# Instalar dependencias e iniciar
yarn install
yarn dev --host
```

### 8. Error de permisos en volúmenes

**Síntomas:**
- Errores de "Permission denied"
- No se pueden escribir archivos

**Solución (macOS/Linux):**
```bash
# Arreglar permisos
sudo chown -R $USER:$USER /Users/moshe/Projects/frape2
chmod -R 755 /Users/moshe/Projects/frape2
```

### 9. Limpiar completamente y empezar de nuevo

```bash
# Parar todo y limpiar
docker compose down -v
docker system prune -a

# O usar el script de gestión
./manage.sh reset
```

### 10. Ver logs específicos

```bash
# Logs de todos los servicios
docker compose logs

# Logs de un servicio específico
docker compose logs frappe
docker compose logs mariadb
docker compose logs redis

# Seguir logs en tiempo real
docker compose logs -f frappe
```

## Comandos de Diagnóstico

### Verificar estado general
```bash
./manage.sh status
```

### Verificar conectividad de red
```bash
docker compose exec frappe ping mariadb
docker compose exec frappe ping redis
```

### Verificar base de datos
```bash
docker compose exec frappe bash -c "cd frappe-bench && bench --site builder.localhost mariadb"
```

### Verificar configuración de sitio
```bash
docker compose exec frappe bash -c "cd frappe-bench && bench --site builder.localhost show-config"
```

## Tiempos Esperados

- **Primera instalación completa:** 10-15 minutos
- **Inicios posteriores:** 2-3 minutos
- **Descarga de imágenes:** 3-5 minutos (dependiendo de conexión)

## Recursos del Sistema Recomendados

- **RAM:** Mínimo 4GB, recomendado 8GB
- **CPU:** 2+ cores
- **Espacio en disco:** 5GB libres mínimo
- **Docker Desktop:** Asignar al menos 4GB de RAM a Docker

## Contacto

Si ninguna de estas soluciones funciona, puedes:

1. Revisar la [documentación oficial](https://docs.frappe.io/builder)
2. Buscar en el [foro de discusión](https://discuss.frappe.io/c/frappe-builder/83)
3. Crear un issue en el [repositorio oficial](https://github.com/frappe/builder/issues)