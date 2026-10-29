# GUION TÉCNICO PARA GRABACIÓN DE VIDEO: TAREA 3.1
**Plataforma de entrega:** YouTube (Enlace Público / Oculto)  
**Requisito de Rúbrica:** Cámara web visible y activa en la **esquina inferior derecha** durante toda la grabación.  
**Duración recomendada:** Entre 5 y 7 minutos.  
**Resolución recomendada:** 1080p (1920x1080), tamaño de fuente de terminal de 16pt o superior para óptima legibilidad.

---

## Checklist Previo a la Grabación (Antes de dar "Rec")

1. [ ] Cámara web configurada en OBS Studio u host en la **esquina inferior derecha**, asegurando que no tape el texto del terminal.
2. [ ] Máquina virtual Debian encendida y conectada vía SSH o terminal limpia.
3. [ ] Scripts copiados a la VM con permisos de ejecución: `chmod +x scripts/*.sh`.
4. [ ] Si ya habías probado el script antes, limpia los usuarios o usa un snapshot limpio para que el video muestre la creación desde cero:
   ```bash
   sudo ./scripts/deprovision_users.sh -d carlos.mendoza
   sudo ./scripts/deprovision_users.sh -d ana.morales
   sudo ./scripts/deprovision_users.sh -d luis.torres
   sudo ./scripts/deprovision_users.sh -d elena.ramirez
   sudo faillock --reset
   ```

---

## Estructura Cronológica del Video (Minuto a Minuto)

```
00:00 - 00:45 | Introducción, presentación personal y objetivos
00:45 - 02:00 | Inspección del CSV y Ejecución del Script de Creación Masiva
02:00 - 03:15 | Demostración de Aislamiento de Homes y Permisos 750
03:15 - 04:15 | Prueba de Primer Login: Expiración y Cambio Forzado de Contraseña
04:15 - 05:15 | Demostración de Sudoers y Políticas de Horario (pam_time)
05:15 - 06:15 | Prueba de Bloqueo por Fuerza Bruta (pam_faillock)
06:15 - 06:45 | Desaprovisionamiento seguro con respaldo y Cierre
```

---

## Escena 1: Introducción y Presentación (00:00 - 00:45)
* **Visual:** Terminal en pantalla completa, cámara web en la esquina inferior derecha.
* **Acción en pantalla:** Mostrar el comando `cat /etc/os-release` o `hostnamectl` para evidenciar que es Debian.
* **Locución (Qué decir):**
  > *"Hola a todos, mi nombre es [Tu Nombre], estudiante de la materia Administración de Servidores. En este video realizaré la demostración práctica de la Tarea 3.1 de la Unidad 3: Automatización de administración de usuarios, grupos y políticas de acceso sobre Debian GNU/Linux.*  
  > *Demostraremos la provisión de cuentas por lotes a través de un archivo CSV, el aislamiento de directorios personales, la expiración de credenciales, el control de horarios con PAM, el acceso seguro mediante sudoers y la protección ante ataques de fuerza bruta con faillock."*

---

## Escena 2: Inspección y Creación por Lotes (00:45 - 02:00)
* **Visual:** Visualizar el archivo CSV y luego correr el script.
* **Comandos a teclear:**
  ```bash
  cat scripts/usuarios.csv
  sudo ./scripts/provision_users.sh scripts/usuarios.csv
  ```
* **Locución (Qué decir):**
  > *"En pantalla tenemos nuestro archivo CSV con los usuarios divididos en cuatro áreas: Sistemas, Finanzas, Operaciones y Dirección. Cada uno cuenta con una contraseña temporal y fecha de caducidad.*  
  > *Procedo a ejecutar el script de aprovisionamiento con privilegios de root.*  
  > *Como pueden observar en la consola, el script crea automáticamente los grupos departamentales si no existen, genera las cuentas con useradd, inyecta la contraseña temporal, fuerza el cambio obligatorio de clave para el primer login con chage y asigna permisos estrictos 750 al directorio home."*

---

## Escena 3: Aislamiento de Directorios Home (02:00 - 03:15)
* **Visual:** Comprobar permisos con `ls -ld` y hacer una prueba de acceso cruzado denegado.
* **Comandos a teclear:**
  ```bash
  ls -ld /home/*
  # Probar acceso cruzado: el usuario de operaciones intenta ver el home de finanzas
  su - luis.torres -c "ls -la /home/ana.morales"
  ```
* **Locución (Qué decir):**
  > *"Para cumplir con el principio de mínimo privilegio y aislamiento de datos, revisamos los permisos en /home. Vemos drwxr-x--- (750). El usuario es dueño de su directorio y su grupo departamental tiene lectura, pero 'otros' no tienen ningún bit activo.*  
  > *Hacemos la prueba con el usuario luis.torres del área de Operaciones intentando listar el contenido del home de ana.morales de Finanzas. El sistema responde de inmediato con 'Permission denied', comprobando el aislamiento total."*

---

## Escena 4: Cambio Obligatorio de Contraseña (03:15 - 04:15)
* **Visual:** Iniciar sesión con un usuario nuevo.
* **Comandos a teclear:**
  ```bash
  su - carlos.mendoza
  # Ingresar contraseña temporal: TempPassTI2026!
  # El sistema solicita la clave actual y pide una nueva
  # Escribir nueva clave segura (ej: NuevaClaveSegura2026!)
  exit
  ```
* **Locución (Qué decir):**
  > *"Ahora simulamos el primer inicio de sesión del usuario carlos.mendoza. Introducimos su contraseña provisional y vemos cómo el sistema intercepta el inicio y fuerza el cambio de contraseña de inmediato debido a la directiva chage -d 0. Hasta que el usuario no introduce una contraseña nueva, no se le permite utilizar la terminal."*

---

## Escena 5: Sudoers y Políticas de Horario (04:15 - 05:15)
* **Visual:** Mostrar la regla de sudoers y las directivas horarias en `/etc/security/time.conf`.
* **Comandos a teclear:**
  ```bash
  cat /etc/sudoers.d/99-sistemas-security
  sudo grep -v '^#' /etc/security/time.conf | grep -v '^$'
  ```
* **Locución (Qué decir):**
  > *"Para la delegación de administración, no dimos acceso genérico. Creamos una regla en sudoers.d que restringe la administración exclusivamente al grupo 'sistemas', exigiendo autenticación propia y registrando cada comando en /var/log/sudo_sistemas.log.*  
  > *Asimismo, a través del módulo pam_time configuramos franjas horarias estrictas: Finanzas y Operaciones solo pueden acceder en días laborales de 8:00 a 17:00 y 18:00 horas respectivamente, mientras que TI y Dirección mantienen disponibilidad continua."*

---

## Escena 6: Prueba de Fuerza Bruta y Bloqueo con faillock (05:15 - 06:15)
* **Visual:** Forzar 3 intentos fallidos de login y mostrar el bloqueo.
* **Comandos a teclear:**
  ```bash
  # Intentos con clave errónea
  su - luis.torres
  # Escribir clave incorrecta 3 veces consecutivas
  # Luego verificar el registro con faillock:
  sudo faillock --user luis.torres
  ```
* **Locución (Qué decir):**
  > *"Veamos la protección activa contra ataques de diccionario o fuerza bruta gestionada por pam_faillock. Intentamos ingresar 3 veces con contraseñas erróneas. Al consultar la herramienta faillock, observamos los 3 fallos registrados y la cuenta de luis.torres queda congelada por 300 segundos, impidiendo cualquier nuevo intento incluso si se teclea la clave correcta."*

---

## Escena 7: Desaprovisionamiento y Conclusión (06:15 - 06:45)
* **Visual:** Probar el script de bajas con respaldo y finalizar.
* **Comandos a teclear:**
  ```bash
  sudo ./scripts/deprovision_users.sh -d mariana.solis
  ls -lh /var/backups/deleted_users/
  ```
* **Locución (Qué decir):**
  > *"Finalmente, cuando un usuario es dado de baja, ejecutamos deprovision_users.sh con el parámetro -d. El script mata sus procesos activos, genera un respaldo comprimido en tar.gz dentro de /var/backups/deleted_users y elimina la cuenta del sistema sin pérdida de información para auditoría.*  
  > *Con esto concluye la validación de la Tarea 3.1, demostrando la administración completa del ciclo de vida y la seguridad del servidor. Muchas gracias por su atención."*
