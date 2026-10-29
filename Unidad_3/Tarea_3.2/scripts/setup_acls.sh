#!/usr/bin/env bash
# ==============================================================================
# Script: setup_acls.sh
# Descripción: Configuración de permisos avanzados POSIX, SGID, Sticky Bit y
#              Listas de Control de Acceso (ACLs) con herencia por defecto.
# Autor: Antigravity AI / Administración de Servidores
# Sistema: Debian GNU/Linux 11/12
# Uso: sudo ./setup_acls.sh
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

BASE_DIR="/srv/compartido"

echo -e "${BLUE}===================================================================${NC}"
echo -e "${CYAN} CONFIGURACIÓN DE PERMISOS AVANZADOS POSIX Y ACLS${NC}"
echo -e "${BLUE}===================================================================${NC}"

# 1. Asegurar instalación de herramientas ACL
if ! command -v setfacl >/dev/null 2>&1; then
    echo -e "${YELLOW}[INSTALANDO] Herramientas ACL no encontradas. Instalando paquete 'acl'...${NC}"
    apt-get update -qq && apt-get install -y acl
fi

# 2. Creación de estructura de directorios compartidos
echo -e "\n${CYAN}1. Creando árbol de directorios en $BASE_DIR...${NC}"
mkdir -p "$BASE_DIR/publico"
mkdir -p "$BASE_DIR/finanzas"
mkdir -p "$BASE_DIR/operaciones"
mkdir -p "$BASE_DIR/sistemas"

# ==============================================================================
# A. STICKY BIT EN DIRECTORIO PÚBLICO
# ==============================================================================
# Modo 1777 (rwxrwxrwt): Todos pueden escribir y crear archivos, pero únicamente
# el propietario del archivo (o root) puede eliminarlo o renombrarlo.
echo -e "\n${CYAN}2. Configurando Sticky Bit en $BASE_DIR/publico...${NC}"
chmod 1777 "$BASE_DIR/publico"
chown root:root "$BASE_DIR/publico"
echo -e "${GREEN}[OK] Sticky Bit (1777) aplicado en $BASE_DIR/publico${NC}"

# ==============================================================================
# B. SGID (SET GROUP ID) EN DIRECTORIOS DEPARTAMENTALES
# ==============================================================================
# Modo 2770 (rwxrws---): Permite que cualquier archivo o subdirectorio creado dentro
# herede automáticamente el grupo propietario de la carpeta padre, y restringe
# a otros usuarios ajenos al departamento.
echo -e "\n${CYAN}3. Configurando SGID (2770) en áreas departamentales...${NC}"

# Finanzas
chown root:finanzas "$BASE_DIR/finanzas"
chmod 2770 "$BASE_DIR/finanzas"

# Operaciones
chown root:operaciones "$BASE_DIR/operaciones"
chmod 2770 "$BASE_DIR/operaciones"

# Sistemas
chown root:sistemas "$BASE_DIR/sistemas"
chmod 2770 "$BASE_DIR/sistemas"

echo -e "${GREEN}[OK] Bit SGID activado con éxito en finanzas, operaciones y sistemas.${NC}"

# ==============================================================================
# C. LISTAS DE CONTROL DE ACCESO (ACLS) AVANZADAS Y HERENCIA (DEFAULT ACL)
# ==============================================================================
echo -e "\n${CYAN}4. Aplicando ACLs personalizadas y directivas de herencia...${NC}"

# Caso de negocio: La Dirección (elena.ramirez) requiere acceso de solo lectura y auditoría
# al directorio confidencial de Finanzas, sin ser miembro del grupo primario finanzas.
if id "elena.ramirez" >/dev/null 2>&1; then
    # ACL explícita sobre el directorio
    setfacl -m u:elena.ramirez:r-x "$BASE_DIR/finanzas"
    # ACL por defecto (herencia para todo archivo o carpeta futura)
    setfacl -d -m u:elena.ramirez:r-x "$BASE_DIR/finanzas"
    echo -e "${GREEN}[OK] ACL concedida a 'elena.ramirez' (r-x) con herencia en $BASE_DIR/finanzas${NC}"
fi

# Asegurar herencia completa de rwx para el grupo finanzas en nuevos archivos
setfacl -d -m g:finanzas:rwx "$BASE_DIR/finanzas"
setfacl -d -m g:operaciones:rwx "$BASE_DIR/operaciones"
setfacl -d -m g:sistemas:rwx "$BASE_DIR/sistemas"

# ==============================================================================
# 5. VALIDACIÓN Y REPORTE
# ==============================================================================
echo -e "\n${BLUE}===================================================================${NC}"
echo -e "${CYAN} VERIFICACIÓN DE PERMISOS POSIX Y GETFACL${NC}"
echo -e "${BLUE}===================================================================${NC}"
ls -ld "$BASE_DIR"/*

echo -e "\n${YELLOW}Inspección de ACL en $BASE_DIR/finanzas:${NC}"
getfacl "$BASE_DIR/finanzas"

echo -e "\n${GREEN}[EXITO] Estructura de permisos POSIX y ACLs desplegada correctamente.${NC}"
