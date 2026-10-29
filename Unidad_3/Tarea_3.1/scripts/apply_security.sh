#!/usr/bin/env bash
# ==============================================================================
# Script: apply_security.sh
# Descripción: Configuración automatizada de directivas de seguridad en Debian:
#              1. Control de sudoers y grupos de administración auditados.
#              2. Políticas de horarios de acceso mediante pam_time.
#              3. Bloqueo automático de cuentas por intentos fallidos (pam_faillock).
# Autor: Antigravity AI / Administración de Servidores
# Sistema: Debian GNU/Linux 11/12
# Uso: sudo ./apply_security.sh
# ==============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

LOG_FILE="/var/log/security_policy_setup.log"
BACKUP_DIR="/etc/pam_security_backup_$(date +%Y%m%d_%H%M%S)"

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[ERROR] Este script debe ejecutarse con privilegios de root (sudo).${NC}" >&2
    exit 1
fi

echo -e "${BLUE}===================================================================${NC}"
echo -e "${CYAN} APLICACIÓN DE DIRECTIVAS DE SEGURIDAD DEL SERVIDOR${NC}"
echo -e "${BLUE}===================================================================${NC}"

mkdir -p "$BACKUP_DIR"
echo -e "${YELLOW}[BACKUP] Respaldando configuraciones críticas en: ${BACKUP_DIR}${NC}"
cp -a /etc/pam.d/ "$BACKUP_DIR/pam.d/"
cp -a /etc/security/ "$BACKUP_DIR/security/"

# ==============================================================================
# 1. CONTROL DE SUDOERS Y GRUPOS ADMINISTRATIVOS
# ==============================================================================
echo -e "\n${CYAN}1. Configurando privilegios de sudoers y grupos de administración...${NC}"

SUDOERS_FILE="/etc/sudoers.d/99-sistemas-security"

cat << 'EOF' > "$SUDOERS_FILE"
# ------------------------------------------------------------------------------
# Directivas de seguridad para el grupo departamental 'sistemas'
# ------------------------------------------------------------------------------
# Requerir autenticación con contraseña del propio usuario
Defaults:%sistemas authenticate

# Registro de comandos en logs de auditoría del sistema
Defaults:%sistemas log_year, logfile="/var/log/sudo_sistemas.log"

# Privilegios administrativos completos para miembros de sistemas
%sistemas ALL=(ALL:ALL) ALL
EOF

chmod 440 "$SUDOERS_FILE"

# Validar sintaxis con visudo
if visudo -cf "$SUDOERS_FILE"; then
    echo -e "${GREEN}[OK] Reglas de sudoers configuradas y validadas con éxito en: $SUDOERS_FILE${NC}"
else
    echo -e "${RED}[ERROR] Error en la sintaxis de sudoers. Revirtiendo...${NC}"
    rm -f "$SUDOERS_FILE"
    exit 1
fi

# ==============================================================================
# 2. RESTRICCIÓN DE HORARIOS DE ACCESO (pam_time)
# ==============================================================================
echo -e "\n${CYAN}2. Configurando restricciones de horarios de acceso (pam_time)...${NC}"

TIME_CONF="/etc/security/time.conf"

# Añadir reglas al final de time.conf si no existen ya
if ! grep -q "POLITICAS DEPARTAMENTALES U3" "$TIME_CONF"; then
cat << 'EOF' >> "$TIME_CONF"

# ------------------------------------------------------------------------------
# POLITICAS DEPARTAMENTALES U3 - RESTRICCION HORARIA
# Sintaxis: servicios;terminales;usuarios;dias_y_horas
# Dias: Mo Tu We Th Fr Sa Su (Wk = Lunes a Viernes, Al = Todos)
# Horas: formato militar 24h (HHMM-HHMM)
# ------------------------------------------------------------------------------
# Operaciones: Acceso permitido únicamente de Lunes a Viernes de 08:00 a 18:00
*;*;@operaciones;Wk0800-1800

# Finanzas: Acceso permitido únicamente de Lunes a Viernes de 08:00 a 17:00
*;*;@finanzas;Wk0800-1700

# Sistemas y Direccion: Acceso irrestricto 24/7
*;*;@sistemas;Al0000-2400
*;*;@direccion;Al0000-2400
EOF
    echo -e "${GREEN}[OK] Reglas horarias añadidas a: $TIME_CONF${NC}"
else
    echo -e "${YELLOW}[INFO] Las reglas horarias ya existen en $TIME_CONF.${NC}"
fi

# Habilitar pam_time en /etc/pam.d/common-account si no está habilitado
PAM_COMMON_ACCOUNT="/etc/pam.d/common-account"
if ! grep -q "pam_time.so" "$PAM_COMMON_ACCOUNT"; then
    echo "account required pam_time.so" >> "$PAM_COMMON_ACCOUNT"
    echo -e "${GREEN}[OK] Módulo 'pam_time.so' activado en $PAM_COMMON_ACCOUNT${NC}"
else
    echo -e "${YELLOW}[INFO] Módulo 'pam_time.so' ya se encontraba presente en PAM.${NC}"
fi

# ==============================================================================
# 3. POLÍTICA DE BLOQUEO POR INTENTOS FALLIDOS (pam_faillock)
# ==============================================================================
echo -e "\n${CYAN}3. Configurando directiva de bloqueo por intentos fallidos (pam_faillock)...${NC}"

FAILLOCK_CONF="/etc/security/faillock.conf"

# Configuración formal de faillock
cat << 'EOF' > "$FAILLOCK_CONF"
# Configuración de bloqueo de cuentas por fuerza bruta
# Bloquear cuenta tras 3 intentos fallidos consecutivos
deny = 3

# Ventana de tiempo (en segundos) para contabilizar intentos: 15 minutos (900s)
fail_interval = 900

# Tiempo de bloqueo temporal: 5 minutos (300s)
unlock_time = 300

# Ocultar mensajes que revelen el motivo del rechazo
silent
EOF

echo -e "${GREEN}[OK] Parámetros de faillock configurados en: $FAILLOCK_CONF (3 intentos, 300s bloqueo).${NC}"

# Integración segura de pam_faillock en PAM
PAM_COMMON_AUTH="/etc/pam.d/common-auth"

if ! grep -q "pam_faillock.so" "$PAM_COMMON_AUTH"; then
    # Crear nueva configuración limpia de common-auth con faillock preauth y authfail
    cat << 'EOF' > "$PAM_COMMON_AUTH"
# Configuración generada por apply_security.sh con soporte pam_faillock
auth    required    pam_faillock.so preauth
auth    [success=1 default=ignore]  pam_unix.so nullok
auth    [default=die]               pam_faillock.so authfail
auth    sufficient                  pam_faillock.so authsucc
auth    requisite                   pam_deny.so
auth    required                    pam_permit.so
EOF
    echo -e "${GREEN}[OK] Gancho de autenticación pam_faillock vinculado en: $PAM_COMMON_AUTH${NC}"
else
    echo -e "${YELLOW}[INFO] pam_faillock ya configurado en $PAM_COMMON_AUTH.${NC}"
fi

# Vinculación en common-account para faillock reset al autenticar exitosamente
if ! grep -q "pam_faillock.so" "$PAM_COMMON_ACCOUNT"; then
    echo "account required pam_faillock.so" >> "$PAM_COMMON_ACCOUNT"
    echo -e "${GREEN}[OK] Gancho de cuenta pam_faillock vinculado en: $PAM_COMMON_ACCOUNT${NC}"
fi

echo -e "\n${BLUE}===================================================================${NC}"
echo -e "${GREEN} [EXITO] TODAS LAS DIRECTIVAS DE SEGURIDAD HAN SIDO APLICADAS${NC}"
echo -e "${BLUE}===================================================================${NC}"
echo -e "• Control Sudoers     : Grupo 'sistemas' con log en /var/log/sudo_sistemas.log"
echo -e "• Horarios (pam_time) : Operaciones (08-18h), Finanzas (08-17h), Sistemas (24/7)"
echo -e "• Bloqueo (faillock)  : 3 intentos fallidos = 300 segundos de bloqueo"
echo -e "${BLUE}===================================================================${NC}"
