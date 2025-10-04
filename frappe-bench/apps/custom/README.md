# Custom Apps Directory

Este directorio es para tus aplicaciones personalizadas de Frappe.

## Como crear una nueva app personalizada:

```bash
# Acceder al contenedor
docker compose exec frappe bash

# Ir al directorio bench
cd /home/frappe/frappe-bench

# Crear nueva app
bench new-app mi_app_personalizada

# La app se creará en apps/mi_app_personalizada/
# Mover a custom/ para versionar:
mv apps/mi_app_personalizada apps/custom/

# Instalar en el sitio
bench --site localhost install-app mi_app_personalizada
```

## Apps Personalizadas Versionadas

Las apps en este directorio se incluyen en el repositorio git para:
- ✅ Versionar tu código personalizado
- ✅ Colaborar en desarrollo 
- ✅ Mantener historial de cambios
- ✅ Deploy automático

Las apps de terceros (frappe, erpnext, builder, etc.) se mantienen como volúmenes Docker.