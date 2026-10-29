#!/usr/bin/env bash
# ==============================================================================
# Script: raid_fail_simulate.sh
# Descripción: Herramienta para simular el fallo inducido de un disco en el RAID,
#              verificar el estado degradado del arreglo, extraer el disco dañado
#              y realizar la reconstrucción (hot rebuild) en caliente.
# Autor: Antigravity AI / Administración de Servidores
# Sistema: Debian GNU/Linux 11/12
# Uso: sudo ./raid_fail_simulate.sh [status | fail | remove | rebuild | full-demo]
# ==============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

RAID_DEVICE="/dev/md0"
LOG_DIR="$(dirname "$0")/../docs/logs"
DEGRADED_LOG="$LOG_DIR/raid_degraded.log"
REBUILD_LOG="$LOG_DIR/raid_rebuild.log"

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[ERROR] Debe ejecutarse con privilegios de root (sudo).${NC}" >&2
    exit 1
fi

mkdir -p "$LOG_DIR"

if ! grep -q "md0" /proc/mdstat 2>/dev/null; then
    echo -e "${RED}[ERROR] El arreglo RAID $RAID_DEVICE no está activo. Ejecuta primero setup_raid.sh.${NC}" >&2
    exit 1
fi

# Detectar el primer disco activo del arreglo
ACTIVE_DEV=$(mdadm --detail "$RAID_DEVICE" | awk '/active sync/ {print $NF}' | head -n 1)

ACTION="${1:-status}"

case "$ACTION" in
    status)
        echo -e "${BLUE}===================================================================${NC}"
        echo -e "${CYAN} ESTADO ACTUAL DEL ARREGLO RAID ($RAID_DEVICE)${NC}"
        echo -e "${BLUE}===================================================================${NC}"
        cat /proc/mdstat
        echo "-------------------------------------------------------------------"
        mdadm --detail "$RAID_DEVICE"
        ;;

    fail)
        if [[ -z "$ACTIVE_DEV" ]]; then
            echo -e "${RED}[ERROR] No se detectaron discos activos en $RAID_DEVICE para inducir fallo.${NC}"
            exit 1
        fi
        echo -e "${YELLOW}===================================================================${NC}"
        echo -e "${RED} INDUCIENDO FALLO EN DISCO: $ACTIVE_DEV ${NC}"
        echo -e "${YELLOW}===================================================================${NC}"

        # Marcar disco como fallido en el kernel
        mdadm --manage "$RAID_DEVICE" --fail "$ACTIVE_DEV"

        echo -e "\n${RED}[ALERTA] Estado degradado del arreglo:${NC}"
        cat /proc/mdstat
        echo "-------------------------------------------------------------------"
        mdadm --detail "$RAID_DEVICE"

        # Guardar log oficial de evidencia de degradación
        {
            echo "=== EVIDENCIA DE ARREGLO DEGRADADO - $(date) ==="
            cat /proc/mdstat
            echo "--------------------------------------------------------"
            mdadm --detail "$RAID_DEVICE"
        } > "$DEGRADED_LOG"
        echo -e "\n${GREEN}[OK] Log de degradación registrado en: $DEGRADED_LOG${NC}"
        ;;

    remove)
        FAILED_DEV=$(mdadm --detail "$RAID_DEVICE" | awk '/faulty/ {print $NF}' | head -n 1)
        if [[ -z "$FAILED_DEV" ]]; then
            echo -e "${RED}[ERROR] No hay ningún disco en estado 'faulty' para remover.${NC}"
            exit 1
        fi
        echo -e "${CYAN}Extrayendo de forma lógica el disco averiado: $FAILED_DEV...${NC}"
        mdadm --manage "$RAID_DEVICE" --remove "$FAILED_DEV"
        echo -e "${GREEN}[OK] Disco extraído. El arreglo continúa operativo en modo tolerante a fallos.${NC}"
        cat /proc/mdstat
        ;;

    rebuild)
        # Re-añadir un disco o el mismo dispositivo reparado para forzar la reconstrucción
        TARGET_DEV="${2:-$ACTIVE_DEV}"
        echo -e "${CYAN}===================================================================${NC}"
        echo -e "${CYAN} RECONSTRUCCIÓN (HOT REBUILD) CON DISCO: $TARGET_DEV${NC}"
        echo -e "${CYAN}===================================================================${NC}"

        mdadm --manage "$RAID_DEVICE" --add "$TARGET_DEV"
        echo -e "${GREEN}[OK] Disco $TARGET_DEV insertado. Iniciando sincronización de paridad/espejo...${NC}"

        # Mostrar progreso de reconstrucción
        cat /proc/mdstat

        {
            echo "=== EVIDENCIA DE RECONSTRUCCIÓN (REBUILD) - $(date) ==="
            cat /proc/mdstat
            echo "--------------------------------------------------------"
            mdadm --detail "$RAID_DEVICE"
        } > "$REBUILD_LOG"
        echo -e "\n${GREEN}[OK] Log de reconstrucción guardado en: $REBUILD_LOG${NC}"
        ;;

    full-demo)
        echo -e "${BLUE}=== INICIANDO DEMOSTRACIÓN COMPLETA DE TOLERANCIA A FALLOS ===${NC}"
        echo -e "\n${CYAN}1. Estado óptimo inicial:${NC}"
        cat /proc/mdstat

        echo -e "\n${RED}2. Simulando desconexión/daño de disco ($ACTIVE_DEV)...${NC}"
        mdadm --manage "$RAID_DEVICE" --fail "$ACTIVE_DEV"
        sleep 2
        cat /proc/mdstat

        echo -e "\n${YELLOW}3. Retirando disco defectuoso...${NC}"
        mdadm --manage "$RAID_DEVICE" --remove "$ACTIVE_DEV"
        sleep 2

        echo -e "\n${GREEN}4. Insertando disco nuevo de reemplazo e iniciando reconstrucción...${NC}"
        mdadm --manage "$RAID_DEVICE" --add "$ACTIVE_DEV"
        cat /proc/mdstat

        # Capturar evidencias
        {
            echo "=== REPORTE DE RESILIENCIA RAID - $(date) ==="
            mdadm --detail "$RAID_DEVICE"
        } > "$REBUILD_LOG"

        echo -e "\n${GREEN}[EXITO] Demostración de fallo y recuperación completada.${NC}"
        ;;

    *)
        echo "Uso: sudo $0 [status | fail | remove | rebuild | full-demo]"
        exit 1
        ;;
esac
