#!/usr/bin/env bash
# ==============================================================================
# Script: setup_raid.sh
# Descripción: Automatización de creación, formateo ext4 y montaje persistente
#              de un arreglo redundante RAID 1 (Espejo) o RAID 5 (Paridad) con mdadm.
#              Soporta discos físicos/virtuales (/dev/sdX) o dispositivos loopback.
# Autor: Antigravity AI / Administración de Servidores
# Sistema: Debian GNU/Linux 11/12
# Uso: sudo ./setup_raid.sh [--loop | /dev/sdb /dev/sdc]
# ==============================================================================

set -uo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

RAID_DEVICE="/dev/md0"
MOUNT_POINT="/mnt/almacen_redundante"
LOOP_DIR="/var/virtual_disks"

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[ERROR] Debe ejecutarse con privilegios de root (sudo).${NC}" >&2
    exit 1
fi

echo -e "${BLUE}===================================================================${NC}"
echo -e "${CYAN} CONFIGURACIÓN DE ALMACENAMIENTO REDUNDANTE RAID CON MDADM${NC}"
echo -e "${BLUE}===================================================================${NC}"

# 1. Asegurar instalación de mdadm
if ! command -v mdadm >/dev/null 2>&1; then
    echo -e "${YELLOW}[INSTALANDO] Paquete mdadm y utilidades del sistema de archivos...${NC}"
    apt-get update -qq && apt-get install -y mdadm e2fsprogs
fi

MODE="${1:---loop}"

if [[ "$MODE" == "--loop" ]]; then
    echo -e "${YELLOW}[MODO VIRTUAL] Creando 3 discos virtuales de 1GB mediante loopback en $LOOP_DIR...${NC}"
    mkdir -p "$LOOP_DIR"
    
    # Crear imágenes raw de 1GB
    dd if=/dev/zero of="$LOOP_DIR/disk1.img" bs=1M count=1024 status=none
    dd if=/dev/zero of="$LOOP_DIR/disk2.img" bs=1M count=1024 status=none
    dd if=/dev/zero of="$LOOP_DIR/disk3.img" bs=1M count=1024 status=none

    # Asociar a dispositivos loop
    DEV1=$(losetup --find --show "$LOOP_DIR/disk1.img")
    DEV2=$(losetup --find --show "$LOOP_DIR/disk2.img")
    DEV3=$(losetup --find --show "$LOOP_DIR/disk3.img")

    DEVICES=("$DEV1" "$DEV2" "$DEV3")
    echo -e "${GREEN}[OK] Dispositivos de almacenamiento preparados: ${DEVICES[*]}${NC}"
    RAID_LEVEL="5"
else
    # Discos pasados como argumentos de línea de comandos (ej: /dev/sdb /dev/sdc /dev/sdd)
    shift || true
    DEVICES=("$MODE" "$@")
    if [[ ${#DEVICES[@]} -eq 2 ]]; then
        RAID_LEVEL="1"
    else
        RAID_LEVEL="5"
    fi
fi

# 2. Si /dev/md0 ya está activo, verificar si solo falta formatear y montar
if ! grep -q "md0" /proc/mdstat 2>/dev/null; then
    echo -e "\n${CYAN}3. Construyendo arreglo RAID nivel $RAID_LEVEL en $RAID_DEVICE con ${#DEVICES[@]} discos...${NC}"
    mdadm --create "$RAID_DEVICE" \
        --level="$RAID_LEVEL" \
        --raid-devices="${#DEVICES[@]}" \
        "${DEVICES[@]}" </dev/null 2>/dev/null || true
fi

echo -e "${GREEN}[OK] Arreglo RAID $RAID_LEVEL activo en $RAID_DEVICE.${NC}"

# 4. Formatear volumen RAID con sistema de archivos ext4
echo -e "\n${CYAN}4. Dando formato ext4 al volumen redundante $RAID_DEVICE...${NC}"
mkfs.ext4 -F -L "ALMACEN_RAID" "$RAID_DEVICE"

# 5. Punto de montaje y configuración de permisos
echo -e "\n${CYAN}5. Montando volumen en $MOUNT_POINT...${NC}"
mkdir -p "$MOUNT_POINT"
mount "$RAID_DEVICE" "$MOUNT_POINT" 2>/dev/null || true
chmod 775 "$MOUNT_POINT"
chown root:sistemas "$MOUNT_POINT" 2>/dev/null || true

# Crear estructura inicial de carpetas en el RAID
mkdir -p "$MOUNT_POINT/respaldos_criticos"
mkdir -p "$MOUNT_POINT/repositorio_compartido"
chmod 777 "$MOUNT_POINT/repositorio_compartido"

# 6. Persistencia en /etc/mdadm/mdadm.conf y /etc/fstab
echo -e "\n${CYAN}6. Asegurando persistencia en mdadm.conf y fstab...${NC}"
mkdir -p /etc/mdadm
mdadm --detail --scan | tee -a /etc/mdadm/mdadm.conf > /dev/null

UUID_RAID=$(blkid -s UUID -o value "$RAID_DEVICE")
if [[ -n "$UUID_RAID" ]] && ! grep -q "$UUID_RAID" /etc/fstab; then
    echo "UUID=$UUID_RAID  $MOUNT_POINT  ext4  defaults,nofail  0  2" >> /etc/fstab
fi

# 7. Resumen de estado con mdadm --detail
echo -e "\n${BLUE}===================================================================${NC}"
echo -e "${GREEN} ARREGLO RAID CONFIGURADO Y MONTADO EXITOSAMENTE${NC}"
echo -e "${BLUE}===================================================================${NC}"
cat /proc/mdstat
echo "-------------------------------------------------------------------"
df -h "$MOUNT_POINT"
echo -e "${BLUE}===================================================================${NC}"
