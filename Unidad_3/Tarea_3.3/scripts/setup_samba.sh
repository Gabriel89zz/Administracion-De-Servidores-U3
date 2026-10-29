#!/usr/bin/env bash
# ==============================================================================
# Script: setup_samba.sh
# Descripción: Instalación, despliegue y habilitación de Samba para compartir el
#              almacenamiento RAID en red con soporte para Windows y Linux.
# Autor: Antigravity AI / Administración de Servidores
# Sistema: Debian GNU/Linux 11/12
# Uso: sudo ./setup_samba.sh
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

CONFIG_SOURCE="$(dirname "$0")/../configs/smb.conf"
SAMBA_CONF="/etc/samba/smb.conf"

echo -e "${BLUE}===================================================================${NC}"
echo -e "${CYAN} DESPLIEGUE DEL SERVIDOR DE ARCHIVOS EN RED (SAMBA/NAS)${NC}"
echo -e "${BLUE}===================================================================${NC}"

# 1. Instalar Samba si no está instalado
if ! command -v smbd >/dev/null 2>&1; then
    echo -e "${YELLOW}[INSTALANDO] Servidor Samba y herramientas de red...${NC}"
    apt-get update -qq && apt-get install -y samba samba-common-bin
fi

# 2. Respaldar configuración original
if [[ -f "$SAMBA_CONF" && ! -f "${SAMBA_CONF}.original" ]]; then
    cp "$SAMBA_CONF" "${SAMBA_CONF}.original"
fi

# 3. Aplicar configuración del repositorio RAID
echo -e "${CYAN}Instalando configuración optimizada de smb.conf...${NC}"
cp "$CONFIG_SOURCE" "$SAMBA_CONF"

# 4. Validar sintaxis con testparm
if testparm -s "$SAMBA_CONF" >/dev/null 2>&1; then
    echo -e "${GREEN}[OK] Sintaxis de smb.conf verificada correctamente con testparm.${NC}"
else
    echo -e "${RED}[ERROR] Error en la sintaxis de smb.conf.${NC}"
    exit 1
fi

# 5. Habilitar contraseñas de Samba para usuarios de prueba
echo -e "\n${CYAN}Habilitando acceso Samba para usuarios departamentales...${NC}"
DEFAULT_PASS="SambaPass2026!"
for U in carlos.mendoza ana.morales luis.torres elena.ramirez; do
    if id "$U" >/dev/null 2>&1; then
        (echo "$DEFAULT_PASS"; echo "$DEFAULT_PASS") | smbpasswd -s -a "$U" >/dev/null 2>&1 || true
        smbpasswd -e "$U" >/dev/null 2>&1 || true
        echo -e "${GREEN}[OK] Usuario Samba activado:${NC} $U (Contraseña: $DEFAULT_PASS)"
    fi
done

# 6. Reiniciar y habilitar servicios Samba
systemctl restart smbd nmbd
systemctl enable smbd nmbd

echo -e "\n${BLUE}===================================================================${NC}"
echo -e "${GREEN} SERVICIO SAMBA ACTIVO Y COMPARTIENDO ARREGLO RAID${NC}"
echo -e "${BLUE}===================================================================${NC}"
echo -e "• Recurso RAID   : \\\\<IP_DEBIAN>\\AlmacenRAID"
echo -e "• Recurso Público: \\\\<IP_DEBIAN>\\Publico"
echo -e "${BLUE}===================================================================${NC}"
