# GUION PARA VIDEO: TAREA 3.2
**Materia:** Administración de Servidores  
**Carrera:** Ingeniería en Informática  
**Tema:** Permisos avanzados (SGID/Sticky/ACLs), Cuotas de disco y Respaldos automatizados  
**Requisito indispensable:** Cámara web visible en la **esquina inferior derecha** todo el tiempo.  
**Duración objetivo:** ~3 a 4 minutos (fluido, práctico y directo).

---

## Tips rápidos antes de grabar:
1. Revisa tu cámara en la esquina inferior derecha.
2. Abre la terminal en la carpeta de la Tarea 3.2:
   ```bash
   cd ~/Administracion-De-Servidores-U3/Unidad_3/Tarea_3.2/
   ```

---

## 🎬 Minuto a Minuto del Video

### 1. Introducción y Contexto (00:00 - 00:45)
* **Qué hacer en pantalla:** Terminal limpia con tu webcam visible.
* **Qué decir:**
  > "Hola a todos, soy [Tu Nombre], estudiante de Ingeniería en Informática, y este video es para la materia de Administración de Servidores, correspondiente a la Tarea 3.2 de la Unidad 3.  
  > Aquí vamos a trabajar con permisos avanzados en el sistema de archivos, cuotas de almacenamiento y una política formal de respaldos con recuperación de datos ante desastres.  
  > Seguimos trabajando sobre nuestra máquina virtual Debian Server en VMware. Elegimos este entorno virtualizado porque nos permite manipular cuotas de disco a nivel de kernel en la partición ext4 y simular escenarios reales de pérdida y restauración de archivos sin comprometer la estabilidad del sistema anfitrión. Vamos directo a los comandos."

---

### 2. Permisos Especiales: Sticky Bit, SGID y ACLs (00:45 - 01:30)
* **Comandos en consola:**
  ```bash
  sudo ./scripts/setup_acls.sh
  ```
* **Qué decir:**
  > "Primero corremos `sudo ./scripts/setup_acls.sh`.  
  > Este script configura tres conceptos fundamentales de Linux:  
  > Primero, el **Sticky Bit** en la carpeta `/srv/compartido/publico` con permisos 1777 (`drwxrwxrwt`). Esto hace que cualquiera pueda crear archivos, pero nadie pueda borrar los archivos de otros.  
  > Segundo, el bit **SGID** en las carpetas departamentales (`drwxrws---`), para que cualquier archivo creado dentro herede automáticamente el grupo del departamento.  
  > Y tercero, aplicamos **ACLs con herencia por defecto** con `setfacl`, para que la usuaria Elena Ramírez de Dirección pueda auditar Finanzas sin cambiar los grupos del sistema."

---

### 3. Cuotas de Disco y Prueba de Límite Duro (01:30 - 02:20)
* **Comandos en consola:**
  ```bash
  sudo ./scripts/setup_quotas.sh setup
  sudo ./scripts/setup_quotas.sh test ana.morales
  ```
* **Qué decir:**
  > "Ahora gestionamos el almacenamiento con cuotas de disco mediante `sudo ./scripts/setup_quotas.sh setup`.  
  > Aquí configuramos cuotas a nivel de kernel en ext4. Vemos con `repquota` que la usuaria `ana.morales` tiene un límite blando de 100 Megas y un límite duro de 120 Megas.  
  > Para demostrar que el servidor hace cumplir el límite, corremos la prueba `test`: intentamos escribir un archivo de 130 Megas con el comando `dd` y fíjense cómo el kernel bloquea la escritura de golpe arrojando: 'Se ha excedido la cuota de disco'. Con esto evitamos que un usuario sature el disco del servidor."

---

### 4. Respaldos Automatizados y Prueba de Restauración (RTO/RPO) (02:20 - 03:30)
* **Comandos en consola:**
  ```bash
  cat crontab/backup.cron
  sudo ./scripts/restore.sh test
  ```
* **Qué decir:**
  > "Para la política de respaldos, definimos un RPO de 24 horas y un RTO menor a una hora. En `backup.cron` dejamos programada la tarea con cron: respaldos completos los domingos e incrementales entre semana.  
  > Y para cerrar, corremos la prueba más importante: `sudo ./scripts/restore.sh test`.  
  > Miren lo que hace el script en tiempo real:  
  > 1. Crea un documento confidencial en Finanzas.  
  > 2. Genera un respaldo completo comprimido con tar y calcula su hash SHA256.  
  > 3. Simula una catástrofe: borra el archivo con `rm -f`.  
  > 4. Ejecuta la restauración, comprueba que la firma SHA256 coincide para evitar archivos corruptos, y extrae la copia.  
  > 5. Al final confirma que el archivo fue recuperado al 100% con su contenido y permisos originales, arrojando 'PRUEBA SUPERADA'. El RTO fue de apenas un segundo."

---

### 5. Cierre Rápido (03:30 - 03:45)
* **Qué decir:**
  > "Con esto comprobamos el funcionamiento completo de los permisos avanzados, las cuotas de disco y el plan de respaldo y recuperación. Los scripts están disponibles en el repo. ¡Muchas gracias!"
