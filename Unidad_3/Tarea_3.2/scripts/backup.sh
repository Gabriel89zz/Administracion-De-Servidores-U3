#!/usr/bin/env bash
# ==============================================================================
# Script: backup.sh
# Descripción: Sistema formal de respaldos automatizados multinivel (Full/Incremental)
#              con compresión gzip, verificación de integridad SHA256, rotación,
#              registro detallado en logs y transferencia a medio secundario.
# Autor: Antigravity AI / Administración de Servidores
# Sistema: Debian GNU/Linux 11/12
# Uso: sudo ./backup.sh [auto | full | inc]
# ==============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

LOG_FILE="/var/log/backup_system.log"
PRIMARY_BACKUP_DIR="/var/backups/sistema"
SECONDARY_MEDIA_DIR="/mnt/backup_storage" # Simulación de disco secundario / NAS
SNAPSHOT_METADATA="${PRIMARY_BACKUP_DIR}/backup_snapshot.snar"

# Directorios críticos a respaldar
SOURCE_DIRECTORIES=(
    "/srv/compartido"
    "/home"
    "/etc/security"
    "/etc/pam.d"
)

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[ERROR] Este script debe ejecutarse con privilegios de root (sudo).${NC}" >&2
    exit 1
fi

mkdir -p "$PRIMARY_BACKUP_DIR"
mkdir -p "$SECONDARY_MEDIA_DIR"
touch "$LOG_FILE"
chmod 600 "$LOG_FILE"

log() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${level} ${message}"
    echo "[$timestamp] [${level//\\033*m/}] ${message//\\033*m/}" >> "$LOG_FILE"
}

# Determinar el modo de respaldo:
# Si es 'auto': Domingo = Full (Nivel 0), Lunes a Sábado = Incremental (Nivel 1)
REQUESTED_MODE="${1:-auto}"
DAY_OF_WEEK=$(date +%u) # 1 = Lunes, 7 = Domingo

if [[ "$REQUESTED_MODE" == "auto" ]]; then
    if [[ "$DAY_OF_WEEK" -eq 7 || ! -f "$SNAPSHOT_METADATA" ]]; then
        BACKUP_TYPE="FULL"
    else
        BACKUP_TYPE="INC"
    fi
elif [[ "$REQUESTED_MODE" == "full" ]]; then
    BACKUP_TYPE="FULL"
else
    BACKUP_TYPE="INC"
fi

TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
ARCHIVE_NAME="backup_${BACKUP_TYPE}_${TIMESTAMP}.tar.gz"
ARCHIVE_PATH="${PRIMARY_BACKUP_DIR}/${ARCHIVE_NAME}"

log "${BLUE}===================================================================${NC}" ""
log "${CYAN} INICIO DE RESPALDO AUTOMATIZADO - TIPO: ${BACKUP_TYPE}${NC}" ""
log "${BLUE}===================================================================${NC}" ""
log "${CYAN}Destino primario :${NC}" "$ARCHIVE_PATH"
log "${CYAN}Fuentes          :${NC}" "${SOURCE_DIRECTORIES[*]}"

START_TIME=$(date +%s)

# Si es respaldo FULL, resetear el archivo de metadatos de snapshot
if [[ "$BACKUP_TYPE" == "FULL" ]]; then
    rm -f "$SNAPSHOT_METADATA"
fi

# Ejecutar el empaquetado y compresión usando tar listado incremental (snar)
log "${YELLOW}[INFO] Empaquetando y comprimiendo con gzip...${NC}" ""

tar -czf "$ARCHIVE_PATH" \
    --listed-incremental="$SNAPSHOT_METADATA" \
    --exclude="*.tmp" \
    --exclude="*.swp" \
    --exclude="*/.cache" \
    "${SOURCE_DIRECTORIES[@]}" 2>> "$LOG_FILE"

# Verificación de integridad del archivo comprimido
log "${YELLOW}[INFO] Verificando integridad del archivo tar.gz...${NC}" ""
if tar -tzf "$ARCHIVE_PATH" >/dev/null 2>&1; then
    log "${GREEN}[OK] Integridad del archivo comprimido validada con éxito.${NC}" ""
else
    log "${RED}[ERROR] El archivo de respaldo presenta daños o corrupción.${NC}" ""
    exit 1
fi

# Cálculo de hash criptográfico SHA-256 para no repudio e integridad
CHECKSUM=$(sha256sum "$ARCHIVE_PATH" | awk '{print $1}')
echo "$CHECKSUM  $ARCHIVE_NAME" > "${ARCHIVE_PATH}.sha256"
log "${GREEN}[OK] Hash SHA256 generado:${NC}" "$CHECKSUM"

# Obtener tamaño del respaldo
BACKUP_SIZE=$(du -h "$ARCHIVE_PATH" | awk '{print $1}')
log "${GREEN}[OK] Tamaño final del paquete:${NC}" "$BACKUP_SIZE"

# Transferencia o sincronización al medio secundario / servidor de almacenamiento
log "${YELLOW}[INFO] Sincronizando respaldo al medio secundario ($SECONDARY_MEDIA_DIR)...${NC}" ""
cp -p "$ARCHIVE_PATH" "$SECONDARY_MEDIA_DIR/"
cp -p "${ARCHIVE_PATH}.sha256" "$SECONDARY_MEDIA_DIR/"
log "${GREEN}[OK] Copia en medio secundario confirmada con éxito.${NC}" ""

# Política de retención (Limpieza de respaldos antiguos)
# Respaldos completos > 30 días, Incrementales > 14 días
log "${YELLOW}[INFO] Aplicando política de rotación y retención...${NC}" ""
find "$PRIMARY_BACKUP_DIR" -name "backup_FULL_*.tar.gz*" -type f -mtime +30 -delete 2>/dev/null || true
find "$PRIMARY_BACKUP_DIR" -name "backup_INC_*.tar.gz*" -type f -mtime +14 -delete 2>/dev/null || true
find "$SECONDARY_MEDIA_DIR" -name "backup_*.tar.gz*" -type f -mtime +30 -delete 2>/dev/null || true

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

log "${BLUE}===================================================================${NC}" ""
log "${GREEN}[EXITO] PROCESO DE RESPALDO FINALIZADO EN ${ELAPSED} SEGUNDOS${NC}" ""
log "${CYAN}Registro histórico en:${NC} $LOG_FILE" ""
log "${BLUE}===================================================================${NC}" ""
