# GUION TÉCNICO PARA GRABACIÓN DE VIDEO: TAREA 3.2
**Plataforma de entrega:** YouTube (Enlace Público / Oculto)  
**Requisito de Rúbrica:** Cámara web visible y activa en la **esquina inferior derecha** durante toda la grabación.  
**Duración recomendada:** Entre 5 y 7 minutos.  
**Resolución recomendada:** 1080p (1920x1080), tamaño de fuente de terminal de 16pt o superior.

---

## Checklist Previo a la Grabación

1. [ ] Cámara web verificada en la **esquina inferior derecha** en OBS Studio o software de grabación.
2. [ ] Sistema de archivos con cuotas activas (`sudo ./scripts/setup_quotas.sh setup`).
3. [ ] Permisos y ACLs configurados (`sudo ./scripts/setup_acls.sh`).
4. [ ] Script `restore.sh` y `backup.sh` listos con permisos de ejecución.

---

## Estructura Cronológica del Video

```
00:00 - 00:45 | Introducción, presentación personal y objetivos de la Tarea 3.2
00:45 - 02:00 | Demostración de Permisos Especiales: Sticky Bit, SGID y ACLs con getfacl
02:00 - 03:15 | Demostración de Cuotas de Disco: repquota y prueba de límite con dd
03:15 - 04:30 | Explicación de la Lógica del Script backup.sh y Programación en Cron
04:30 - 05:30 | Ejecución Manual del Respaldo, Integridad y Hash SHA256
05:30 - 06:30 | Prueba en Vivo de Recuperación de Archivos Borrados (RTO/RPO)
06:30 - 07:00 | Conclusiones y Cierre
```

---

## Escena 1: Introducción y Presentación (00:00 - 00:45)
* **Visual:** Terminal despejada, cámara web en la esquina inferior derecha.
* **Locución (Qué decir):**
  > *"Hola a todos, soy [Tu Nombre], estudiante de Administración de Servidores. En esta entrega abordaremos la Tarea 3.2: Permisos avanzados, cuotas de disco y política de respaldos automatizados sobre Debian GNU/Linux.*  
  > *Veremos en vivo cómo estructurar carpetas colaborativas seguras con Sticky Bit y SGID, cómo aplicar cuotas a nivel de kernel para evitar el agotamiento de espacio, la lógica técnica de nuestro script de respaldos multinivel con validación criptográfica y, finalmente, una prueba real de recuperación de un archivo crítico eliminado."*

---

## Escena 2: Permisos Especiales y ACLs (00:45 - 02:00)
* **Visual:** Listado de `/srv/compartido` y lectura de ACLs con `getfacl`.
* **Comandos a teclear:**
  ```bash
  ls -ld /srv/compartido/*
  getfacl /srv/compartido/finanzas
  ```
* **Locución (Qué decir):**
  > *"Comenzamos inspeccionando la estructura en /srv/compartido. Noten en la carpeta 'publico' el permiso drwxrwxrwt: la 't' final indica el Sticky Bit activado. Cualquiera puede crear archivos aquí, pero solo el propietario legítimo puede borrarlos.*  
  > *Por otro lado, en las áreas de finanzas, operaciones y sistemas vemos drwxrws---: la 's' corresponde al bit SGID. Esto garantiza que cualquier documento creado dentro pertenezca automáticamente al grupo del departamento.*  
  > *Además, con getfacl observamos que la usuaria elena.ramirez de Dirección cuenta con una ACL de lectura y ejecución con herencia default, permitiéndole auditar sin perturbar los grupos primarios."*

---

## Escena 3: Cuotas de Disco y Prueba de Límite Duro (02:00 - 03:15)
* **Visual:** Ejecutar `repquota` y probar el desbordamiento con `dd`.
* **Comandos a teclear:**
  ```bash
  sudo repquota -as
  sudo ./scripts/setup_quotas.sh test ana.morales
  ```
* **Locución (Qué decir):**
  > *"Pasamos al control de recursos. Con repquota -as consultamos el estado de cuotas del kernel. La usuaria ana.morales tiene un límite blando de 100 MB y un límite duro de 120 MB.*  
  > *Para demostrar que el kernel hace cumplir la directiva, ejecutamos la prueba con dd intentando escribir un archivo de 130 MB. Observen en la terminal: el sistema interrumpe la operación de golpe con el mensaje 'Disk quota exceeded'. Con esto evitamos que un usuario llene la partición del servidor."*

---

## Escena 4: Lógica de Respaldo y Calendarización en Cron (03:15 - 04:30)
* **Visual:** Mostrar el código de `backup.sh` y el archivo de cron.
* **Comandos a teclear:**
  ```bash
  cat crontab/backup.cron
  head -n 35 scripts/backup.sh
  ```
* **Locución (Qué decir):**
  > *"Diseñamos una política formal con un RPO de 24 horas y un RTO de menos de 1 hora. En el archivo crontab programamos una tarea desatendida: los domingos a las 2 AM se ejecuta un respaldo COMPLETO nivel 0, y de lunes a sábado a la misma hora se ejecutan respaldos INCREMENTALES nivel 1.*  
  > *El script backup.sh utiliza el motor de snapshot snar de GNU tar para detectar únicamente los bloques modificados, aplica compresión gzip, calcula la firma criptográfica SHA256 y sincroniza una copia en un medio secundario."*

---

## Escena 5: Ejecución Manual y Hashes (04:30 - 05:30)
* **Visual:** Ejecutar el respaldo completo en la consola y ver el log.
* **Comandos a teclear:**
  ```bash
  sudo ./scripts/backup.sh full
  ls -lh /var/backups/sistema/
  cat /var/log/backup_system.log | tail -n 12
  ```
* **Locución (Qué decir):**
  > *"Ejecutamos manualmente el respaldo completo. En cuestión de segundos, el script empaqueta las áreas de /srv/compartido, /home y las configuraciones de seguridad. Valida la integridad del archivo tar, calcula su hash SHA256, reporta el tamaño final y confirma la copia al directorio secundario. Todo queda asentado en /var/log/backup_system.log para fines de auditoría."*

---

## Escena 6: Prueba en Vivo de Recuperación de Archivos Borrados (05:30 - 06:30)
* **Visual:** Correr el modo de prueba automatizado de `restore.sh test`.
* **Comandos a teclear:**
  ```bash
  sudo ./scripts/restore.sh test
  ```
* **Locución (Qué decir):**
  > *"Ahora realizaremos la prueba de fuego de nuestro plan de recuperación ante desastres con el comando restore.sh test.*  
  > *Paso 1: Se crea un archivo confidencial con información financiera.*  
  > *Paso 2: Generamos el respaldo.*  
  > *Paso 3: Simulamos la catástrofe: eliminamos el archivo por completo con rm -f.*  
  > *Paso 4: El script de restauración valida la firma SHA256 del paquete para descartar manipulación y extrae el respaldo.*  
  > *Paso 5: Comprobamos el resultado. Como vemos en pantalla, el documento reaparece intacto, con sus permisos originales y contenido verificado. El RTO fue de escasos segundos."*

---

## Escena 7: Conclusión (06:30 - 07:00)
* **Visual:** Regreso a la terminal principal con los scripts.
* **Locución (Qué decir):**
  > *"Con estas pruebas hemos demostrado el cumplimiento cabal de la Tarea 3.2: permisos POSIX avanzados para colaboración segura, control de almacenamiento mediante cuotas y un esquema robusto y probado de respaldos y recuperación. Muchas gracias y nos vemos en la Tarea 3.3."*
