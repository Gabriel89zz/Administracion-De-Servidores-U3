#!/usr/bin/env bash
# ==============================================================================
# Script: provision_users.sh
# Descripción: Automatización de creación por lotes de usuarios, asignación de 
#              directorios home aislados, contraseñas temporales forzadas,
#              fechas de expiración y membresía a grupos departamentales.
# Autor: Antigravity AI / Administración de Servidores
# Sistema: Debian GNU/Linux 11/12
# Uso: sudo ./provision_users.sh [ruta_archivo_csv]
# ==============================================================================

set -euo pipefail

# Colores para salida enriquecida
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # Sin color

LOG_FILE="/var/log/user_provisioning.log"
CSV_FILE="${1:-usuarios.csv}"

# 1. Comprobación de privilegios de superusuario
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[ERROR] Este script debe ser ejecutado con privilegios de root (sudo).${NC}" >&2
    exit 1
fi

# 2. Verificación de existencia del archivo CSV
if [[ ! -f "$CSV_FILE" ]]; then
    echo -e "${RED}[ERROR] No se encontró el archivo de usuarios: '$CSV_FILE'${NC}" >&2
    exit 1
fi

echo -e "${BLUE}===================================================================${NC}"
echo -e "${CYAN} INICIO DE PROVISIÓN MASIVA DE USUARIOS - DEBIAN SERVER${NC}"
echo -e "${BLUE}===================================================================${NC}"
echo -e "${CYAN}Archivo origen :${NC} $CSV_FILE"
echo -e "${CYAN}Archivo de log :${NC} $LOG_FILE"
echo -e "${CYAN}Fecha y hora   :${NC} $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "${BLUE}-------------------------------------------------------------------${NC}"

# Inicializar o rotar el archivo de log
touch "$LOG_FILE"
chmod 600 "$LOG_FILE"
echo "=== Nueva sesión de aprovisionamiento: $(date) ===" >> "$LOG_FILE"

TOTAL_PROCESADOS=0
TOTAL_CREADOS=0
TOTAL_OMITIDOS=0
TOTAL_ERRORES=0

# Función para registrar logs
log_msg() {
    local status="$1"
    local message="$2"
    echo -e "${status} ${message}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [${status//\\033*m/}] ${message//\\033*m/}" >> "$LOG_FILE"
}

# 3. Procesar archivo CSV línea por línea
# Estructura: username,nombre,apellido,departamento,grupos_secundarios,fecha_expiracion,password_temporal
while IFS=',' read -r USERNAME NOMBRE APELLIDO DEPARTAMENTO GRUPOS_SEC FECHA_EXP PASSWORD_TEMP || [[ -n "$USERNAME" ]]; do
    # Omitir líneas vacías o comentadas (#)
    [[ -z "$USERNAME" || "$USERNAME" =~ ^[[:space:]]*# ]] && continue

    # Limpieza de espacios en blanco
    USERNAME=$(echo "$USERNAME" | xargs)
    NOMBRE=$(echo "$NOMBRE" | xargs)
    APELLIDO=$(echo "$APELLIDO" | xargs)
    DEPARTAMENTO=$(echo "$DEPARTAMENTO" | xargs)
    GRUPOS_SEC=$(echo "$GRUPOS_SEC" | xargs)
    FECHA_EXP=$(echo "$FECHA_EXP" | xargs)
    PASSWORD_TEMP=$(echo "$PASSWORD_TEMP" | xargs)

    ((TOTAL_PROCESADOS++))

    # A. Validar que el grupo primario (departamento) exista, o crearlo automáticamente
    if ! getent group "$DEPARTAMENTO" >/dev/null 2>&1; then
        groupadd "$DEPARTAMENTO"
        log_msg "${YELLOW}[INFO]${NC}" "Grupo departamental primario '${DEPARTAMENTO}' creado."
    fi

    # B. Verificar si el usuario ya existe
    if id "$USERNAME" >/dev/null 2>&1; then
        log_msg "${YELLOW}[OMITIDO]${NC}" "El usuario '${USERNAME}' ya existe en el sistema."
        ((TOTAL_OMITIDOS++))
        continue
    fi

    # C. Validar y crear grupos secundarios si están especificados
    if [[ -n "$GRUPOS_SEC" ]]; then
        IFS=';' read -ra GRUPOS_ARRAY <<< "$GRUPOS_SEC"
        for GRP in "${GRUPOS_ARRAY[@]}"; do
            GRP=$(echo "$GRP" | xargs)
            if ! getent group "$GRP" >/dev/null 2>&1; then
                groupadd "$GRP"
                log_msg "${YELLOW}[INFO]${NC}" "Grupo secundario '${GRP}' creado para '${USERNAME}'."
            fi
        done
    fi

    # D. Creación de cuenta de usuario con useradd
    # -m : Crear directorio home
    # -s : Shell bash predeterminado
    # -g : Grupo primario
    # -c : Nombre completo (GECOS)
    # -e : Fecha de expiración de cuenta (formato YYYY-MM-DD)
    USERADD_CMD=(useradd -m -s /bin/bash -g "$DEPARTAMENTO" -c "$NOMBRE $APELLIDO")
    if [[ -n "$FECHA_EXP" ]]; then
        USERADD_CMD+=(-e "$FECHA_EXP")
    fi
    USERADD_CMD+=("$USERNAME")

    if "${USERADD_CMD[@]}"; then
        # E. Asignar grupos secundarios si existen
        if [[ -n "$GRUPOS_SEC" ]]; then
            # Reemplazar ; por , para el comando usermod
            GRUPOS_COMMAS="${GRUPOS_SEC//;/,}"
            usermod -aG "$GRUPOS_COMMAS" "$USERNAME"
        fi

        # F. Asignar contraseña temporal mediante chpasswd
        echo "${USERNAME}:${PASSWORD_TEMP}" | chpasswd

        # G. Forzar cambio obligatorio de contraseña en el primer inicio de sesión (chage -d 0)
        chage -d 0 "$USERNAME"

        # H. Aislamiento estricto del directorio Home
        # Permiso 750 (rwxr-x---): Propietario tiene control total, grupo primario lectura/ejecución,
        # resto del mundo (otros usuarios) SIN NINGÚN ACCESO (aislamiento total interdepartamental).
        HOME_DIR="/home/${USERNAME}"
        if [[ -d "$HOME_DIR" ]]; then
            chmod 750 "$HOME_DIR"
            chown "${USERNAME}:${DEPARTAMENTO}" "$HOME_DIR"
        fi

        log_msg "${GREEN}[OK]${NC}" "Usuario '${USERNAME}' creado [Dept: ${DEPARTAMENTO}, Exp: ${FECHA_EXP:-N/A}, Home: 750 (Aislado)]"
        ((TOTAL_CREADOS++))
    else
        log_msg "${RED}[ERROR]${NC}" "Fallo al crear la cuenta para '${USERNAME}'."
        ((TOTAL_ERRORES++))
    fi

done < "$CSV_FILE"

# 4. Resumen ejecutivo final
echo -e "${BLUE}===================================================================${NC}"
echo -e "${CYAN} RESUMEN DE PROCESAMIENTO${NC}"
echo -e "${BLUE}===================================================================${NC}"
echo -e "Total registros leídos : ${TOTAL_PROCESADOS}"
echo -e "Usuarios creados       : ${GREEN}${TOTAL_CREADOS}${NC}"
echo -e "Usuarios omitidos      : ${YELLOW}${TOTAL_OMITIDOS}${NC}"
echo -e "Errores encontrados    : ${RED}${TOTAL_ERRORES}${NC}"
echo -e "Log detallado          : ${CYAN}${LOG_FILE}${NC}"
echo -e "${BLUE}===================================================================${NC}"
