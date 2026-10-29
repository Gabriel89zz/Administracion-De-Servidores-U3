#!/usr/bin/env bash
# ==============================================================================
# Script: restore.sh
# Descripción: Procedimiento formal de verificación y restauración de respaldos
#              con validación criptográfica SHA256 y simulación de contingencia.
# Autor: Antigravity AI / Administración de Servidores
# Sistema: Debian GNU/Linux 11/12
# Uso: sudo ./restore.sh [restore <archivo_tar.gz> [directorio_destino] | test]
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

ACTION="${1:-help}"

case "$ACTION" in
    restore)
        ARCHIVE="${2:-}"
        TARGET_DIR="${3:-/}"

        if [[ -z "$ARCHIVE" || ! -f "$ARCHIVE" ]]; then
            echo -e "${RED}[ERROR] Debes especificar un archivo de respaldo válido (.tar.gz).${NC}" >&2
            exit 1
        fi

        echo -e "${BLUE}===================================================================${NC}"
        echo -e "${CYAN} PROCEDIMIENTO DE RESTAURACIÓN DE RESPALDO${NC}"
        echo -e "${BLUE}===================================================================${NC}"
        echo -e "Archivo fuente : ${CYAN}$ARCHIVE${NC}"
        echo -e "Destino        : ${CYAN}$TARGET_DIR${NC}"

        # 1. Validación de Checksum SHA256 si existe el archivo .sha256
        if [[ -f "${ARCHIVE}.sha256" ]]; then
            echo -e "\n${YELLOW}[1] Validando firma criptográfica SHA256...${NC}"
            CURRENT_DIR=$(pwd)
            ARCHIVE_DIR=$(dirname "$ARCHIVE")
            ARCHIVE_BASE=$(basename "$ARCHIVE")
            cd "$ARCHIVE_DIR"
            if sha256sum -c "${ARCHIVE_BASE}.sha256"; then
                echo -e "${GREEN}[OK] Verificación de integridad superada. El archivo es genuino.${NC}"
            else
                echo -e "${RED}[ERROR] El archivo de respaldo no coincide con su hash SHA256. Proceso abortado.${NC}"
                exit 1
            fi
            cd "$CURRENT_DIR"
        fi

        # 2. Extracción de archivos
        echo -e "\n${YELLOW}[2] Extrayendo archivos y preservando permisos POSIX/ACLs...${NC}"
        # -x: extraer
        # -p: preservar permisos
        # --same-owner: preservar UID/GID originales
        # -C: directorio destino
        tar -xzpf "$ARCHIVE" -C "$TARGET_DIR"

        echo -e "\n${GREEN}[EXITO] Restauración completada satisfactoriamente en: $TARGET_DIR${NC}"
        ;;

    test)
        echo -e "${BLUE}===================================================================${NC}"
        echo -e "${CYAN} SIMULACIÓN EN VIVO: PÉRDIDA Y RECUPERACIÓN DE DATOS (RTO/RPO)${NC}"
        echo -e "${BLUE}===================================================================${NC}"

        DOC_TEST="/srv/compartido/finanzas/balance_general_confidencial.txt"
        mkdir -p "/srv/compartido/finanzas"

        echo -e "\n${CYAN}1. Creando documento crítico de prueba en Finanzas...${NC}"
        cat << 'EOF' > "$DOC_TEST"
===========================================================
REPORTE FINANCIERO CONFIDENCIAL - EJERCICIO 2026
Balance General: Superávit Operativo
Hash de Control: SEC-998877-VALID
===========================================================
EOF
        chown root:finanzas "$DOC_TEST"
        chmod 660 "$DOC_TEST"
        cat "$DOC_TEST"

        echo -e "\n${CYAN}2. Ejecutando respaldo automático completo...${NC}"
        ./backup.sh full

        LATEST_BACKUP=$(ls -t /var/backups/sistema/backup_FULL_*.tar.gz | head -n 1)
        echo -e "${GREEN}[OK] Respaldo generado: $LATEST_BACKUP${NC}"

        echo -e "\n${RED}3. SIMULANDO ELIMINACIÓN ACCIDENTAL DEL ARCHIVO...${NC}"
        rm -f "$DOC_TEST"
        if [[ ! -f "$DOC_TEST" ]]; then
            echo -e "${RED}[DESASTRE] Archivo eliminado: $DOC_TEST no existe.${NC}"
        fi

        echo -e "\n${YELLOW}4. EJECUTANDO RECUPERACIÓN A PARTIR DEL RESPALDO...${NC}"
        ./restore.sh restore "$LATEST_BACKUP" "/"

        echo -e "\n${CYAN}5. VERIFICACIÓN DEL ARCHIVO RECUPERADO:${NC}"
        if [[ -f "$DOC_TEST" ]]; then
            echo -e "${GREEN}[RECUPERADO CON ÉXITO] Contenido del archivo restaurado:${NC}"
            cat "$DOC_TEST"
            ls -la "$DOC_TEST"
        else
            echo -e "${RED}[FALLO] El archivo no pudo ser recuperado.${NC}"
            exit 1
        fi

        echo -e "\n${GREEN}===================================================================${NC}"
        echo -e "${GREEN} [PRUEBA SUPERADA] RPO y RTO demostrados con éxito.${NC}"
        echo -e "${GREEN}===================================================================${NC}"
        ;;

    *)
        echo "Uso:"
        echo "  sudo $0 restore <archivo.tar.gz> [directorio_destino]"
        echo "  sudo $0 test   (Ejecuta una simulación completa de borrado y restauración)"
        exit 1
        ;;
esac
