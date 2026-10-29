#!/usr/bin/env bash
# ==============================================================================
# Script: setup_cups.sh
# Descripción: Instalación y configuración del Servidor de Impresión CUPS en Debian,
#              administración de colas por TCP/IP, priorización y pruebas de red.
# Autor: Antigravity AI / Administración de Servidores
# Sistema: Debian GNU/Linux 11/12
# Uso: sudo ./setup_cups.sh [setup | test-print]
# ==============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[ERROR] Debe ejecutarse con privilegios de root (sudo).${NC}" >&2
    exit 1
fi

ACTION="${1:-setup}"
CONFIG_SOURCE="$(dirname "$0")/../configs/cupsd.conf"
CUPSD_TARGET="/etc/cups/cupsd.conf"

case "$ACTION" in
    setup)
        echo -e "${BLUE}===================================================================${NC}"
        echo -e "${CYAN} CONFIGURACIÓN DEL SERVIDOR DE IMPRESIÓN CUPS (TCP/IP)${NC}"
        echo -e "${BLUE}===================================================================${NC}"

        # 1. Instalar paquetes de CUPS y driver virtual PDF
        if ! command -v cupsd >/dev/null 2>&1; then
            echo -e "${YELLOW}[INSTALANDO] Servidor CUPS y controlador cups-pdf...${NC}"
            apt-get update -qq && apt-get install -y cups cups-client cups-filters printer-driver-cups-pdf
        fi

        # 2. Desplegar cupsd.conf
        echo -e "${CYAN}Aplicando archivo de configuración cupsd.conf...${NC}"
        cp "$CONFIG_SOURCE" "$CUPSD_TARGET"
        chmod 640 "$CUPSD_TARGET"

        # 3. Asignar grupo lpadmin al usuario administrador carlos.mendoza
        if id "carlos.mendoza" >/dev/null 2>&1; then
            usermod -aG lpadmin carlos.mendoza
            echo -e "${GREEN}[OK] Usuario 'carlos.mendoza' agregado al grupo 'lpadmin' para gestión web.${NC}"
        fi

        # 4. Iniciar servicio CUPS
        systemctl restart cups
        systemctl enable cups

        # 5. Configurar Colas de Impresión
        echo -e "\n${CYAN}5. Configurando colas de impresión con diferenciación de prioridades...${NC}"

        # Eliminar colas previas si existen
        lpadmin -x "Cola_Estandar" 2>/dev/null || true
        lpadmin -x "Cola_Urgente" 2>/dev/null || true

        # Crear Cola_Estandar (PDF, compartida en red)
        lpadmin -p "Cola_Estandar" \
            -E \
            -v "cups-pdf:/" \
            -m "raw" \
            -D "Impresora Compartida Departamental (Prioridad Estandar)" \
            -L "Servidor Central" \
            -o printer-is-shared=true

        # Crear Cola_Urgente (PDF, compartida en red con prioridad)
        lpadmin -p "Cola_Urgente" \
            -E \
            -v "cups-pdf:/" \
            -m "raw" \
            -D "Impresora de Alta Prioridad / Documentos Urgentes" \
            -L "Servidor Central" \
            -o printer-is-shared=true

        # Habilitar y aceptar trabajos
        cupsenable Cola_Estandar Cola_Urgente
        cupsaccept Cola_Estandar Cola_Urgente

        # Fijar Cola_Estandar como impresora por omisión del sistema
        lpoptions -d "Cola_Estandar"

        echo -e "${GREEN}[OK] Colas de impresión creadas, compartidas y activas.${NC}"

        # 6. Reporte de estado
        echo -e "\n${BLUE}===================================================================${NC}"
        echo -e "${GREEN} SERVIDOR CUPS OPERATIVO POR TCP/IP EN PUERTO 631${NC}"
        echo -e "${BLUE}===================================================================${NC}"
        lpstat -p -d
        echo -e "\nPanel Web de Gestión: http://<IP_SERVIDOR>:631"
        ;;

    test-print)
        echo -e "${CYAN}Ejecutando prueba de envío de trabajos y asignación de prioridades...${NC}"
        
        # Crear documento de prueba temporal
        TEST_DOC="/tmp/prueba_impresion.txt"
        cat << 'EOF' > "$TEST_DOC"
==============================================================
PRUEBA DE IMPRESION EN RED - SERVIDOR DEBIAN CUPS
Materia: Administracion de Servidores - Unidad 3
Fecha: $(date)
Prioridad Asignada: ALTA / URGENTE (100)
==============================================================
EOF

        echo -e "${YELLOW}Enviando trabajo con prioridad estándar (job-priority=20) a Cola_Estandar...${NC}"
        JOB1=$(lp -d Cola_Estandar -o job-priority=20 "$TEST_DOC" 2>&1)
        echo -e "${GREEN}[OK] $JOB1${NC}"

        echo -e "${YELLOW}Enviando trabajo con alta prioridad (job-priority=100) a Cola_Urgente...${NC}"
        JOB2=$(lp -d Cola_Urgente -o job-priority=100 "$TEST_DOC" 2>&1)
        echo -e "${GREEN}[OK] $JOB2${NC}"

        echo -e "\n${CYAN}Inspeccionando estado de las colas de impresión (lpq / lpstat):${NC}"
        lpstat -o
        rm -f "$TEST_DOC"
        echo -e "\n${GREEN}[EXITO] Prueba de impresión en red finalizada satisfactoriamente.${NC}"
        ;;

    *)
        echo "Uso: sudo $0 [setup | test-print]"
        exit 1
        ;;
esac
