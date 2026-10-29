#!/usr/bin/env bash
# ==============================================================================
# Script: verify_system.sh
# Descripción: Herramienta de auditoría y validación para la Tarea 3.1.
#              Permite comprobar el aislamiento de directorios, directivas chage,
#              estado de bloqueo de cuentas (faillock) y reseteo manual.
# Autor: Antigravity AI / Administración de Servidores
# Sistema: Debian GNU/Linux 11/12
# Uso: sudo ./verify_system.sh [check | unlock <usuario> | test-login <usuario>]
# ==============================================================================

set -uo pipefail

# Asegurar que las herramientas de /usr/sbin estén en el PATH
export PATH="/usr/sbin:/sbin:$PATH"

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

ACTION="${1:-check}"
TARGET_USER="${2:-}"

case "$ACTION" in
    check)
        echo -e "${BLUE}===================================================================${NC}"
        echo -e "${CYAN} AUDITORÍA DE SEGURIDAD Y CONFIGURACIÓN - TAREA 3.1${NC}"
        echo -e "${BLUE}===================================================================${NC}"

        echo -e "\n${YELLOW}[1] VERIFICACIÓN DE AISLAMIENTO DE DIRECTORIOS HOME (/home):${NC}"
        echo "Permisos esperados: drwxr-x--- (750) o drwx------ (700)"
        echo "-------------------------------------------------------------------"
        ls -ld /home/*/ 2>/dev/null || echo "No hay directorios de usuarios creados."

        echo -e "\n${YELLOW}[2] POLÍTICAS DE ENVEJECIMIENTO DE CONTRASEÑA Y EXPIRACIÓN (chage):${NC}"
        echo "-------------------------------------------------------------------"
        for U in carlos.mendoza ana.morales luis.torres elena.ramirez; do
            if id "$U" >/dev/null 2>&1; then
                echo -e "${CYAN}Usuario: $U${NC}"
                chage -l "$U" 2>/dev/null || true
                echo "-------------------------------------------------------------------"
            fi
        done

        echo -e "\n${YELLOW}[3] ESTADO DE BLOQUEO POR INTENTOS FALLIDOS (faillock):${NC}"
        echo "-------------------------------------------------------------------"
        if command -v faillock >/dev/null 2>&1; then
            faillock || echo "No hay intentos fallidos registrados actualmente."
        else
            echo "Comando faillock no disponible en el sistema."
        fi

        echo -e "\n${YELLOW}[4] COMPROBACIÓN DE REGLAS DE SUDOERS:%sistemas${NC}"
        echo "-------------------------------------------------------------------"
        if [[ -f /etc/sudoers.d/99-sistemas-security ]]; then
            cat /etc/sudoers.d/99-sistemas-security
        else
            echo "Archivo de sudoers personalizado no encontrado."
        fi

        echo -e "\n${YELLOW}[5] REGLAS DE ACCESO HORARIO ACTIVAS (/etc/security/time.conf):${NC}"
        echo "-------------------------------------------------------------------"
        grep -v '^[[:space:]]*#' /etc/security/time.conf | grep -v '^$' || echo "Sin reglas activas."

        echo -e "\n${GREEN}[OK] Auditoría completada con éxito.${NC}"
        ;;

    unlock)
        if [[ -z "$TARGET_USER" ]]; then
            echo -e "${RED}[ERROR] Especifica el usuario a desbloquear. Ejemplo: sudo ./verify_system.sh unlock luis.torres${NC}"
            exit 1
        fi
        echo -e "${CYAN}Desbloqueando al usuario '$TARGET_USER'...${NC}"
        faillock --user "$TARGET_USER" --reset
        usermod -U "$TARGET_USER" 2>/dev/null || true
        echo -e "${GREEN}[OK] Usuario '$TARGET_USER' desbloqueado y contador reiniciado.${NC}"
        ;;

    *)
        echo "Uso: sudo $0 [check | unlock <usuario>]"
        exit 1
        ;;
esac
