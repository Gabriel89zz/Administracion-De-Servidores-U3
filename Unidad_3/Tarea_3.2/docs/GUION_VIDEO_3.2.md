# GUION PARA VIDEO: TAREA 3.2
**Materia:** Administración de Servidores  
**Carrera:** Ingeniería en Informática  
**Tema:** Permisos avanzados, cuotas de disco y política de respaldos automatizados  
**Requisito indispensable:** Cámara web visible en la **esquina inferior derecha** todo el tiempo.  
**Duración estimada:** ~4 a 5 minutos (explicativo, conectado y demostrativo).

---

## 📌 Contexto inicial antes de grabar:
* Tener la terminal abierta en la carpeta de la práctica:
  ```bash
  cd ~/Administracion-De-Servidores-U3/Unidad_3/Tarea_3.2/
  ```
* En este video ejecutaremos en orden exacto los comandos de las **Instrucciones Rápidas de Ejecución del README**:
  1. `chmod +x scripts/*.sh`
  2. `sudo ./scripts/setup_acls.sh`
  3. `sudo ./scripts/setup_quotas.sh setup`
  4. `sudo ./scripts/backup.sh full`
  5. `sudo cat /var/log/backup_system.log | tail -n 12`
  6. `sudo ./scripts/restore.sh test`

---

## 🎬 Minuto a Minuto del Video

### 1. Introducción y Contexto (00:00 - 00:45)
* **Qué hacer en pantalla:** Terminal limpia con la cámara web activa en la esquina inferior derecha.
* **Qué decir:**
  > "Qué tal a todos, mi nombre es [Tu Nombre], estudiante de Ingeniería en Informática en la materia de Administración de Servidores. En este video abordaremos la Tarea 3.2 de la Unidad 3: Permisos avanzados en sistemas de archivos, cuotas de almacenamiento y política formal de respaldos automatizados con recuperación ante desastres.  
  > Seguimos trabajando en nuestra máquina virtual con Debian Server en VMware Workstation. Trabajar en un entorno virtualizado es ideal para esta práctica porque nos permite habilitar y reconfigurar cuotas a nivel de kernel directamente sobre el sistema de archivos ext4 y, lo más importante, simular escenarios destructivos de pérdida y recuperación de archivos sin poner en riesgo absoluto los datos de nuestra computadora física.  
  > Procedemos a ejecutar en orden exacto los pasos señalados en el README."

---

### 2. Permisos Especiales y Listas de Control de Acceso (Paso 1 y 2 del README) (00:45 - 01:50)
* **Comandos en consola:**
  ```bash
  chmod +x scripts/*.sh
  sudo ./scripts/setup_acls.sh
  ```
* **Qué decir:**
  > "Iniciamos otorgando permisos de ejecución con `chmod +x scripts/*.sh`.  
  > En el paso 2 aplicamos los permisos especiales y ACLs ejecutando: `sudo ./scripts/setup_acls.sh`.  
  > Analicemos con atención los tres conceptos técnicos que este script acaba de desplegar:  
  > Primero: en la carpeta `/srv/compartido/publico` configuramos permisos en modo octal **1777** (`drwxrwxrwt`). La 't' al final representa el **Sticky Bit**. En Linux, esto permite que cualquier usuario pueda crear y compartir archivos, pero nadie puede renombrar ni eliminar archivos de otro usuario; únicamente el dueño legítimo o root pueden hacerlo.  
  > Segundo: en las carpetas departamentales como `/srv/compartido/finanzas` aplicamos modo **2770** (`drwxrws---`). La 's' representa el bit **SGID** (Set Group ID). Esto resuelve el problema clásico de colaboración: cualquier archivo que se cree dentro de la carpeta heredará automáticamente el grupo propietario 'finanzas', garantizando que todos los compañeros del área puedan editarlo de inmediato.  
  > Y tercero: las **ACLs (Listas de Control de Acceso)** con herencia por defecto mediante `setfacl`. En la salida de `getfacl` observamos la regla `default:user:elena.ramirez:r-x`. Esto permite que la Directora General tenga permisos de lectura y auditoría continua en Finanzas sin tener que pertenecer a ese grupo primario."

---

### 🟢 Conexión hacia el Paso 3:
> *"Ya logramos que la colaboración sea segura mediante permisos y ACLs. Sin embargo, en cualquier servidor donde múltiples usuarios comparten almacenamiento existe el riesgo de que alguien consuma todo el espacio en disco, ya sea por negligencia o saturación. Por eso, en el paso 3 aprenderemos a regular el uso del almacenamiento mediante cuotas de disco."*

---

### 3. Configuración y Control de Cuotas de Disco (Paso 3 del README) (01:50 - 02:45)
* **Comandos en consola:**
  ```bash
  sudo ./scripts/setup_quotas.sh setup
  ```
* **Qué decir:**
  > "Corremos el paso 3: `sudo ./scripts/setup_quotas.sh setup`.  
  > Aquí intervenimos el subsistema de almacenamiento: el script agrega las directivas `usrjquota` y `grpjquota` en `/etc/fstab`, remonta la partición ext4, inicializa los registros con `quotacheck` y activa el monitoreo en el kernel con `quotaon`.  
  > ¿Cómo funcionan las cuotas? Se definen dos umbrales:  
  > El **Límite Blando (Soft Limit)**, que en este caso fijamos en 100 Megas para `ana.morales`: si la usuaria lo supera, el sistema le da un periodo de gracia de 7 días pero le permite seguir guardando.  
  > Y el **Límite Duro (Hard Limit)**, que fijamos en 120 Megas: este es un techo infranqueable. Si el usuario intenta sobrepasar este límite, el kernel cancela la escritura en seco con el error 'Disk quota exceeded', protegiendo la partición del servidor contra saturación."

---

### 🟢 Conexión hacia el Paso 4:
> *"Con los permisos gobernados y el espacio en disco estrictamente controlado, nos falta el pilar más crítico de cualquier administrador de infraestructura: la continuidad del negocio y la protección de los datos. En el paso 4 ejecutaremos nuestro sistema formal de respaldos automatizados."*

---

### 4. Respaldo Manual Completo y Verificación Criptográfica (Paso 4 del README) (02:45 - 03:40)
* **Comandos en consola:**
  ```bash
  sudo ./scripts/backup.sh full
  sudo cat /var/log/backup_system.log | tail -n 12
  ```
* **Qué decir:**
  > "En el paso 4 ejecutamos un respaldo completo ejecutando: `sudo ./scripts/backup.sh full`.  
  > Para esta práctica diseñamos una política formal de respaldos con dos métricas de negocio fundamentales:  
  > El **RPO (Punto Objetivo de Recuperación)** fijado en 24 horas, que indica que ante un desastre nunca perderemos más de un día de información gracias a copias incrementales diarias.  
  > Y el **RTO (Tiempo Objetivo de Recuperación)** fijado en menos de 60 minutos.  
  > El script empaqueta las áreas críticas de `/srv/compartido`, `/home` y las configuraciones de seguridad; las comprime en gzip; verifica que el paquete tar no esté dañado; calcula un hash criptográfico **SHA-256** para asegurar que el archivo no sea alterado ni corrompido, y lo transfiere automáticamente a una ruta de almacenamiento secundario.  
  > Al inspeccionar el log con `sudo cat /var/log/backup_system.log | tail -n 12`, comprobamos el registro exacto de cada fase, el tamaño final y la duración en segundos."

---

### 🟢 Conexión hacia el Paso 5:
> *"Un respaldo no sirve de nada si nunca hemos probado restaurarlo. De nada nos sirve tener archivos comprimidos si al momento de una contingencia real fallan. Por eso, en el paso 5 realizaremos una simulación completa de pérdida y recuperación de archivos en vivo."*

---

### 5. Simulación de Desastre y Recuperación Exitosa (Paso 5 del README) (03:40 - 04:30)
* **Comandos en consola:**
  ```bash
  sudo ./scripts/restore.sh test
  ```
* **Qué decir:**
  > "Concluimos con el paso 5 ejecutando nuestra prueba de fuego: `sudo ./scripts/restore.sh test`.  
  > Observemos la secuencia en la terminal:  
  > 1. El script genera un archivo confidencial de balances en el departamento de Finanzas.  
  > 2. Corre el respaldo automático completo.  
  > 3. Simula una catástrofe humana o técnica: borra el archivo con `rm -f`.  
  > 4. Inicia el proceso de contingencia: primero valida que la firma SHA-256 del respaldo coincida exactamente, asegurando la autenticidad e integridad del paquete.  
  > 5. Extrae los datos preservando permisos y confirma que el archivo reaparece con su contenido y metadatos idénticos, arrojando el mensaje verde 'PRUEBA SUPERADA'. El RTO real demostrado fue de apenas un segundo.  
  > Con esto demostramos la gestión avanzada de permisos, cuotas y respaldos de la Tarea 3.2. ¡Muchas gracias por su atención!"
