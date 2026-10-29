#!/usr/bin/env bash
# ==============================================================================
# Script: setup_quotas.sh
# Descripción: Habilitación, inicialización y asignación de cuotas de disco
#              por usuario y grupo en sistemas de archivos ext4 en Debian.
# Autor: Antigravity AI / Administración de Servidores
# Sistema: Debian GNU/Linux 11/12
# Uso: sudo ./setup_quotas.sh [setup | test <usuario>]
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
MOUNT_POINT="/"

case "$ACTION" in
    setup)
        echo -e "${BLUE}===================================================================${NC}"
        echo -e "${CYAN} CONFIGURACIÓN DE CUOTAS DE DISCO POR USUARIO Y GRUPO${NC}"
        echo -e "${BLUE}===================================================================${NC}"

        # 1. Instalar paquetes de cuotas si no están presentes
        if ! command -v quotacheck >/dev/null 2>&1 || ! command -v setquota >/dev/null 2>&1; then
            echo -e "${YELLOW}[INSTALANDO] Paquete quota y dependencias...${NC}"
            apt-get update -qq && apt-get install -y quota quotatool
        fi

        # 2. Verificar y habilitar opciones en /etc/fstab para el sistema de archivos raíz
        FSTAB="/etc/fstab"
        if ! grep -E "${MOUNT_POINT}[[:space:]]+ext4" "$FSTAB" | grep -q "usrquota"; then
            echo -e "${YELLOW}[INFO] Añadiendo usrquota y grpquota al punto de montaje en $FSTAB...${NC}"
            cp "$FSTAB" "${FSTAB}.bak_quota"
            # Reemplazar 'errors=remount-ro' o 'defaults' por las directivas de cuotas seguras
            sed -i.bak -E "s|([[:space:]]+ext4[[:space:]]+)(defaults\|errors=remount-ro)|\1\2,usrjquota=aquota.user,grpjquota=aquota.group,jqfmt=vfsv1|g" "$FSTAB"
            echo -e "${GREEN}[OK] Opciones de cuota añadidas a /etc/fstab.${NC}"
            
            echo -e "${YELLOW}[INFO] Remontando partición $MOUNT_POINT con soporte de cuotas...${NC}"
            mount -o remount "$MOUNT_POINT"
        else
            echo -e "${GREEN}[OK] Opciones de cuotas ya configuradas en $FSTAB.${NC}"
        fi

        # 3. Inicializar bases de datos de cuota (aquota.user, aquota.group)
        echo -e "\n${CYAN}3. Verificando e inicializando base de datos de cuotas (quotacheck)...${NC}"
        # -a: todos los sistemas de archivos montados con cuota
        # -v: verbose
        # -u: usuario
        # -g: grupo
        # -m: no intentar remontar solo lectura
        quotacheck -avugm || true

        # 4. Activar el subsistema de cuotas
        echo -e "\n${CYAN}4. Activando subsistema de cuotas en el kernel (quotaon)...${NC}"
        quotaon -avug 2>/dev/null || true

        # 5. Asignación de cuotas de usuario y grupo
        # Sintaxis setquota: setquota -u <user> <block-soft> <block-hard> <inode-soft> <inode-hard> <filesystem>
        # 1 Bloque = 1 KB. 
        # 100 MB = 102400 KB | 120 MB = 122880 KB
        echo -e "\n${CYAN}5. Asignando límites de cuota formales...${NC}"

        # Cuota para usuario modelo: ana.morales (Finanzas)
        # Límite blando: 100 MB, Límite duro: 120 MB, Inodos: 1000 soft, 1200 hard
        if id "ana.morales" >/dev/null 2>&1; then
            setquota -u ana.morales 102400 122880 1000 1200 "$MOUNT_POINT"
            echo -e "${GREEN}[OK] Cuota individual configurada para 'ana.morales': Soft=100MB, Hard=120MB${NC}"
        fi

        # Cuota para usuario modelo: luis.torres (Operaciones)
        if id "luis.torres" >/dev/null 2>&1; then
            setquota -u luis.torres 81920 102400 800 1000 "$MOUNT_POINT"
            echo -e "${GREEN}[OK] Cuota individual configurada para 'luis.torres': Soft=80MB, Hard=100MB${NC}"
        fi

        # Cuota departamental grupal: grupo finanzas
        # Soft: 500 MB (512000 KB), Hard: 600 MB (614400 KB)
        if getent group "finanzas" >/dev/null 2>&1; then
            setquota -g finanzas 512000 614400 5000 6000 "$MOUNT_POINT"
            echo -e "${GREEN}[OK] Cuota grupal configurada para grupo 'finanzas': Soft=500MB, Hard=600MB${NC}"
        fi

        # 6. Reporte de estado con repquota
        echo -e "\n${BLUE}===================================================================${NC}"
        echo -e "${CYAN} REPORTE DE CUOTAS ACTIVAS (repquota)${NC}"
        echo -e "${BLUE}===================================================================${NC}"
        repquota -as
        ;;

    test)
        TARGET_USER="${2:-ana.morales}"
        echo -e "${CYAN}Simulando prueba de excedente de cuota para '$TARGET_USER'...${NC}"
        TEST_DIR="/home/$TARGET_USER/prueba_cuota"
        mkdir -p "$TEST_DIR"
        chown "$TARGET_USER:" "$TEST_DIR"

        echo -e "${YELLOW}Generando archivo de 130MB para forzar el límite DURO (Hard Limit 120MB)...${NC}"
        # Se ejecuta como el usuario para que el kernel aplique la cuota
        su - "$TARGET_USER" -c "dd if=/dev/zero of=~/prueba_cuota/test_overflow.bin bs=1M count=130" 2>&1 || true

        echo -e "\n${YELLOW}Inspeccionando alerta de cuota del usuario:${NC}"
        quota -vs "$TARGET_USER"

        echo -e "\n${CYAN}Limpiando archivo de prueba...${NC}"
        rm -rf "$TEST_DIR"
        echo -e "${GREEN}[OK] Prueba de cuota completada.${NC}"
        ;;

    *)
        echo "Uso: sudo $0 [setup | test <usuario>]"
        exit 1
        ;;
esac
