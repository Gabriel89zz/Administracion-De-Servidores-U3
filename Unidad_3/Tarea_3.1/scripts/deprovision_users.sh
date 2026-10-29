#!/usr/bin/env bash
# ==============================================================================
# Script: deprovision_users.sh
# Descripción: Automatización de bajas de usuarios con respaldo de directorio home,
#              terminación de procesos activos y bloqueo o eliminación auditada.
# Autor: Antigravity AI / Administración de Servidores
# Sistema: Debian GNU/Linux 11/12
# Uso: sudo ./deprovision_users.sh [-l | -d] <username>
#      -l : Bloqueo seguro (soft delete: congela cuenta, mata procesos, no borra home)
#      -d : Eliminación definitiva (hard delete: respalda home a tar.gz y borra cuenta)
# ==============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

LOG_FILE="/var/log/user_provisioning.log"
BACKUP_DIR="/var/backups/deleted_users"

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[ERROR] Este script debe ejecutarse con privilegios de root (sudo).${NC}" >&2
    exit 1
fi

usage() {
    echo -e "${YELLOW}Uso:${NC} sudo $0 [-l | -d] <nombre_de_usuario>"
    echo "  -l  Bloqueo de seguridad (deshabilita login, preserva archivos)"
    echo "  -d  Baja definitiva (respalda home en $BACKUP_DIR y elimina la cuenta)"
    exit 1
}

if [[ $# -lt 2 ]]; then
    usage
fi

ACTION="$1"
TARGET_USER="$2"

# Verificar existencia del usuario
if ! id "$TARGET_USER" >/dev/null 2>&1; then
    echo -e "${RED}[ERROR] El usuario '${TARGET_USER}' no existe en el sistema.${NC}" >&2
    exit 1
fi

# Prevenir eliminación de usuarios críticos del sistema
UID_USER=$(id -u "$TARGET_USER")
if [[ $UID_USER -lt 1000 ]]; then
    echo -e "${RED}[SEGURIDAD] No se permite la baja de usuarios del sistema (UID < 1000): '${TARGET_USER}'.${NC}" >&2
    exit 1
fi

mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"

log_action() {
    local msg="$1"
    echo -e "$msg"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [BAJAS] ${msg//\\033*m/}" >> "$LOG_FILE"
}

case "$ACTION" in
    -l|--lock)
        log_action "${CYAN}=== INICIANDO BLOQUEO TEMPORAL DE '${TARGET_USER}' ===${NC}"
        # 1. Terminar procesos activos del usuario
        pkill -u "$TARGET_USER" || true
        # 2. Bloquear contraseña y expirar cuenta inmediatamente
        usermod -L "$TARGET_USER"
        usermod -e 1 "$TARGET_USER"
        # 3. Cambiar shell a /sbin/nologin
        chsh -s /sbin/nologin "$TARGET_USER"
        log_action "${GREEN}[OK] Usuario '${TARGET_USER}' bloqueado y sesión cerrada con éxito.${NC}"
        ;;

    -d|--delete)
        log_action "${CYAN}=== INICIANDO BAJA DEFINITIVA DE '${TARGET_USER}' ===${NC}"
        # 1. Terminar procesos
        pkill -u "$TARGET_USER" || true

        # 2. Respaldo de seguridad del directorio home
        USER_HOME="/home/${TARGET_USER}"
        TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
        BACKUP_ARCHIVE="${BACKUP_DIR}/${TARGET_USER}_home_${TIMESTAMP}.tar.gz"

        if [[ -d "$USER_HOME" ]]; then
            log_action "${YELLOW}[INFO] Generando respaldo comprimido de '${USER_HOME}'...${NC}"
            tar -czf "$BACKUP_ARCHIVE" -C /home "$TARGET_USER"
            log_action "${GREEN}[OK] Respaldo almacenado en: ${BACKUP_ARCHIVE}${NC}"
        fi

        # 3. Eliminar usuario y su directorio home
        userdel -r "$TARGET_USER"
        log_action "${GREEN}[OK] Cuenta '${TARGET_USER}' y directorio home eliminados del sistema.${NC}"
        ;;

    *)
        usage
        ;;
esac
