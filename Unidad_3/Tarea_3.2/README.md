# Tarea 3.2: Permisos Avanzados, Cuotas de Disco y Política de Respaldos Automatizados

## Descripción General
Esta práctica implementa el diseño de permisos avanzados en el sistema de archivos (SGID, Sticky Bit y Listas de Control de Acceso POSIX con herencia), asignación y control de cuotas de almacenamiento para usuarios y grupos, y una política formal de respaldos con automatización mediante `cron`, compresión, hashes criptográficos SHA256 y simulación de contingencia de recuperación de datos (RTO/RPO).

---

## Estructura de Archivos
* **`scripts/setup_acls.sh`**: Configura directorios departamentales colaborativos con `SGID (2770)`, área de intercambio con `Sticky Bit (1777)` y ACLs avanzadas de auditoría con herencia (`default ACL`).
* **`scripts/setup_quotas.sh`**: Habilita e inicializa cuotas de disco en `ext4`, fija límites blandos (soft) y duros (hard) por usuario y grupo, y permite simular desbordamientos.
* **`scripts/backup.sh`**: Motor de respaldos multinivel (Full / Incremental), compresión `tar.gz`, verificación de integridad, generación de firmas SHA256, rotación y copiado a medio secundario.
* **`scripts/restore.sh`**: Procedimiento de validación criptográfica y restauración de respaldos con modo de prueba integrado (`test`) para simular desastres y recuperación.
* **`crontab/backup.cron`**: Plantilla de calendarización periódica para `/etc/cron.d/`.
* **`docs/Reporte_Tecnico_3.2.md`**: Reporte técnico formal con diseño RTO/RPO, tablas de cuotas y evidencias.
* **`docs/GUION_VIDEO_3.2.md`**: Guion para la grabación del video en YouTube con cámara web visible.

---

## Instrucciones Rápidas de Ejecución en Debian

1. **Permisos de ejecución:**
   ```bash
   chmod +x scripts/*.sh
   ```

2. **Configurar permisos avanzados y ACLs:**
   ```bash
   sudo ./scripts/setup_acls.sh
   ```

3. **Habilitar y configurar cuotas de disco:**
   ```bash
   sudo ./scripts/setup_quotas.sh setup
   ```

4. **Ejecutar respaldo manual y verificar:**
   ```bash
   sudo ./scripts/backup.sh full
   cat /var/log/backup_system.log
   ```

5. **Demostración de recuperación de archivos borrados:**
   ```bash
   sudo ./scripts/restore.sh test
   ```
