# Tarea 3.1: Automatización de Administración de Usuarios, Grupos y Políticas de Acceso

## Descripción General
Esta práctica implementa la gestión integral de identidades y directivas de acceso para un entorno corporativo sobre **Debian GNU/Linux 11/12**, cumpliendo con los estándares de aislamiento de datos, expiración de credenciales, auditoría de elevación de privilegios y protección contra ataques de fuerza bruta.

---

## Estructura de Archivos
* **`scripts/usuarios.csv`**: Archivo con la lista de usuarios organizados por departamento, fecha de caducidad y credencial temporal.
* **`scripts/provision_users.sh`**: Script para creación masiva de cuentas, asignación de homes restrictivos (modo `750`), cambio forzado de clave al primer inicio (`chage -d 0`) y grupos secundarios.
* **`scripts/deprovision_users.sh`**: Script para congelamiento (soft delete) o baja definitiva con respaldo comprimido del home a `/var/backups/deleted_users/`.
* **`scripts/apply_security.sh`**: Configuración de restricciones horarias (`pam_time`), bloqueo por intentos fallidos (`pam_faillock`) y control de `sudoers` auditado en `/var/log/sudo_sistemas.log`.
* **`scripts/verify_system.sh`**: Script de auditoría rápida para validar permisos de directorios, directivas de envejecimiento y reseteo de bloqueos.
* **`docs/Manual_Tecnico_3.1.md`**: Manual técnico exhaustivo listo para exportación a PDF.
* **`docs/GUION_VIDEO_3.1.md`**: Guion cronológico con comandos exactos para la grabación del video en YouTube.

---

## Instrucciones Rápidas de Ejecución en Debian

1. **Dar permisos de ejecución a los scripts:**
   ```bash
   chmod +x scripts/*.sh
   ```

2. **Ejecutar el aprovisionamiento de usuarios:**
   ```bash
   sudo ./scripts/provision_users.sh scripts/usuarios.csv
   ```

3. **Aplicar las políticas de seguridad del sistema:**
   ```bash
   sudo ./scripts/apply_security.sh
   ```

4. **Auditar el estado del sistema:**
   ```bash
   sudo ./scripts/verify_system.sh check
   ```

5. **Simular desaprovisionamiento o reseteo de cuentas:**
   ```bash
   # Bloqueo temporal de un usuario:
   sudo ./scripts/deprovision_users.sh -l mariana.solis

   # Desbloquear usuario tras pruebas de fuerza bruta:
   sudo ./scripts/verify_system.sh unlock luis.torres
   ```
