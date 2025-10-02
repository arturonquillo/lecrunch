#!/bin/bash

# Script limpio para gestionar Frappe Builder

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

show_info() {
    echo -e "${GREEN}🌐 Acceso:${NC}"
    echo "   • http://builder.localhost:8000"
    echo "   • http://builder.localhost:8000/builder"
    echo -e "${GREEN}🔑 Credenciales:${NC} Administrator / admin"
}

case "$1" in
    start)
        echo -e "${YELLOW}🚀 Iniciando servicios...${NC}"
        docker compose up -d
        show_info
        ;;
    stop)
        echo -e "${YELLOW}🛑 Deteniendo servicios...${NC}"
        docker compose down
        ;;
    logs)
        echo -e "${YELLOW}📊 Logs en tiempo real (Ctrl+C para salir)...${NC}"
        docker compose logs -f frappe
        ;;
    status)
        docker compose ps
        ;;
    restart)
        echo -e "${YELLOW}🔄 Reiniciando...${NC}"
        docker compose restart
        show_info
        ;;
    clean)
        echo -e "${RED}⚠️  Eliminar todos los datos? (y/N):${NC}"
        read -r confirm
        if [[ $confirm == [yY] ]]; then
            docker compose down -v
            echo -e "${GREEN}✅ Limpiado${NC}"
        fi
        ;;
    shell)
        docker compose exec frappe bash
        ;;
    *)
        echo -e "${CYAN}Uso: $0 {start|stop|logs|status|restart|clean|shell}${NC}"
        show_info
        ;;
esac