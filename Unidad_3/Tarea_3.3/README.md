# Tarea 3.3: Configuración de Almacenamiento Redundante (RAID/NAS) y Colas de Impresión

## Descripción General
Esta práctica aborda la alta disponibilidad en el subsistema de almacenamiento y los servicios periféricos de red sobre **Debian GNU/Linux 11/12**. Se implementa un arreglo de discos redundante por software (**RAID 1 / RAID 5** mediante `mdadm`), su exportación en red local mediante **Samba (SMB/CIFS)** y **NFS**, un procedimiento de simulación de fallo y recuperación en caliente (*hot rebuild*), y un servidor de impresión corporativo (**CUPS**) con colas diferenciadas por prioridades y compartición mediante TCP/IP.

---

## Estructura de Archivos
* **`scripts/setup_raid.sh`**: Creación, formato ext4 y montaje persistente del arreglo RAID en `/mnt/almacen_redundante`. Soporta discos físicos/virtuales (`/dev/sdX`) o dispositivos virtuales loopback (`--loop`).
* **`scripts/raid_fail_simulate.sh`**: Herramienta de auditoría y simulación de fallos (marcar disco defectuoso, verificar degradación, retirar disco dañado y realizar reconstrucción en caliente).
* **`scripts/setup_samba.sh`**: Aprovisionamiento del servidor NAS Samba con integración del volumen RAID y usuarios departamentales.
* **`scripts/setup_cups.sh`**: Despliegue de CUPS, creación de colas (`Cola_Estandar` y `Cola_Urgente`), administración de prioridades y script de pruebas de impresión en red.
* **`configs/smb.conf`**: Configuración optimizada de recursos compartidos en red.
* **`configs/exports`**: Plantilla de compartición por NFS.
* **`configs/cupsd.conf`**: Configuración de seguridad, administración web y escucha TCP/IP en puerto 631 para CUPS.
* **`docs/logs/`**: Evidencia en bruto del estado degradado (`raid_degraded.log`) y reconstruido (`raid_rebuild.log`).
* **`docs/Reporte_Tecnico_3.3.md`**: Reporte técnico exhaustivo con diagramas de volumen RAID, simulación y configuración de colas.
* **`docs/GUION_VIDEO_3.3.md`**: Guion cronológico con comandos exactos para la grabación en YouTube con cámara web visible.

---

## Instrucciones Rápidas de Ejecución en Debian

1. **Permisos de ejecución:**
   ```bash
   chmod +x scripts/*.sh
   ```

2. **Crear y montar el arreglo RAID con los 3 discos de VMware:**
   ```bash
   sudo ./scripts/setup_raid.sh /dev/sdb /dev/sdc /dev/sdd
   ```

3. **Desplegar servidor Samba sobre el RAID:**
   ```bash
   sudo ./scripts/setup_samba.sh
   ```

4. **Desplegar servidor de impresión CUPS:**
   ```bash
   sudo ./scripts/setup_cups.sh setup
   sudo ./scripts/setup_cups.sh test-print
   ```

5. **Simulación de fallo y reconstrucción del RAID:**
   ```bash
   # Inducir fallo y ver degradación:
   sudo ./scripts/raid_fail_simulate.sh fail

   # Reconstruir en caliente:
   sudo ./scripts/raid_fail_simulate.sh rebuild
   ```
