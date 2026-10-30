# GUION PARA VIDEO: TAREA 3.1
**Materia:** Administración de Servidores  
**Carrera:** Ingeniería en Informática  
**Tema:** Automatización de administración de usuarios, grupos y políticas de acceso  
**Requisito indispensable:** Cámara web visible en la **esquina inferior derecha** todo el tiempo.  
**Duración estimada:** ~4 a 5 minutos (conectado, fluido y con explicaciones técnicas claras).

---

## 📌 Contexto inicial antes de grabar:
* Tener la terminal abierta en la carpeta de la práctica:
  ```bash
  cd ~/Administracion-De-Servidores-U3/Unidad_3/Tarea_3.1/
  ```
* En este video ejecutaremos en orden exacto los comandos de las **Instrucciones Rápidas de Ejecución del README**:
  1. `chmod +x scripts/*.sh`
  2. `sudo ./scripts/provision_users.sh scripts/usuarios.csv`
  3. `sudo ./scripts/apply_security.sh`
  4. `sudo ./scripts/verify_system.sh check`
  5. `sudo ./scripts/deprovision_users.sh -l mariana.solis`
  6. `sudo ./scripts/verify_system.sh unlock luis.torres`

---

## 🎬 Minuto a Minuto del Video

### 1. Introducción y Contexto (00:00 - 00:45)
* **Qué hacer en pantalla:** Terminal limpia con la cámara web activa en la esquina inferior derecha.
* **Qué decir:**
  > "Qué tal a todos, mi nombre es [Tu Nombre], estudiante de la carrera de Ingeniería en Informática, y este video corresponde a la materia de Administración de Servidores.  
  > Hoy vamos a desarrollar la Tarea 3.1 de la Unidad 3, enfocada en la automatización de usuarios, grupos departamentales y directivas de seguridad.  
  > Como contexto importante: toda esta práctica la estamos realizando dentro de una máquina virtual con Debian Server sobre VMware Workstation. Trabajar en un entorno virtualizado es indispensable en administración de servidores porque nos provee un entorno aislado y seguro donde podemos manipular directivas de bajo nivel como módulos PAM, reglas de sudoers y cuentas del sistema operativo sin poner en riesgo nuestra máquina anfitriona física, permitiéndonos simular con exactitud cómo operaría un servidor empresarial dedicado.  
  > Vamos a comenzar preparando los permisos y ejecutando los comandos en el orden exacto del README."

---

### 2. Permisos y Aprovisionamiento Masivo (Paso 1 y 2 del README) (00:45 - 01:50)
* **Comandos en consola:**
  ```bash
  chmod +x scripts/*.sh
  sudo ./scripts/provision_users.sh scripts/usuarios.csv
  ```
* **Qué decir:**
  > "Iniciamos otorgando permisos de ejecución a nuestros scripts en Bash mediante `chmod +x scripts/*.sh`.  
  > Ahora procedemos con el paso 2 del README: ejecutar la provisión automatizada con `sudo ./scripts/provision_users.sh scripts/usuarios.csv`.  
  > ¿Qué está sucediendo aquí técnicamente? El script lee un archivo delimitado por comas donde están definidos los empleados divididos en cuatro departamentos: Sistemas, Finanzas, Operaciones y Dirección.  
  > Por cada registro, el script valida si el grupo departamental existe; si no, lo crea con `groupadd`. Después invoca `useradd` para dar de alta la cuenta con su propio directorio `/home`, le asigna una shell `/bin/bash` y establece una fecha de caducidad.  
  > Además, mediante `chpasswd` inyecta una contraseña provisional y con la herramienta `chage -d 0` fuerza a que el usuario deba cambiar su clave obligatoriamente en su primer inicio de sesión.  
  > Y en cuanto a permisos de archivos, aplica un modo octal estricto **750** (`rwxr-x---`) en cada home. Esto significa que el dueño tiene control total, los compañeros de su mismo grupo departamental tienen lectura y ejecución, pero el resto de usuarios ajenos al área tienen cero permisos, garantizando el aislamiento de datos entre departamentos."

---

### 🟢 Conexión hacia el Paso 3:
> *"Una vez que nuestras cuentas ya están creadas y con sus carpetas protegidas, el siguiente paso indispensable en el ciclo de vida del servidor es blindar el acceso mediante directivas de seguridad a nivel de sistema. Por eso pasamos al paso 3: aplicar las reglas de sudoers, control de horarios y protección contra fuerza bruta."*

---

### 3. Aplicar Políticas de Seguridad (Paso 3 del README) (01:50 - 02:45)
* **Comandos en consola:**
  ```bash
  sudo ./scripts/apply_security.sh
  ```
* **Qué decir:**
  > "Ejecutamos el paso 3: `sudo ./scripts/apply_security.sh`.  
  > Este script interactúa directamente con el núcleo de seguridad de Linux y configura tres pilares fundamentales:  
  > Primero: la delegación administrativa con **Sudoers**. En lugar de darle permisos de superusuario a cualquiera, se crea una regla específica en `/etc/sudoers.d/` para el grupo 'sistemas'. Esta directiva exige que el usuario confirme su propia contraseña al usar `sudo` y registra cada comando ejecutado en una bitácora de auditoría en `/var/log/sudo_sistemas.log`.  
  > Segundo: restricción de franjas horarias mediante el módulo **`pam_time`** en `/etc/security/time.conf`. Con esto garantizamos que departamentos como Finanzas y Operaciones solo puedan iniciar sesión de lunes a viernes en horario laboral (de 8 a 17 y 18 horas), mientras que TI mantiene disponibilidad 24/7.  
  > Y tercero: protección activa contra ataques de fuerza bruta o diccionario mediante el módulo **`pam_faillock`**. Este módulo monitorea los intentos de autenticación: si alguien falla su contraseña tres veces consecutivas, su cuenta se bloquea automáticamente durante 300 segundos."

---

### 🟢 Conexión hacia el Paso 4:
> *"Ahora bien, como administradores no podemos dar por hecho que las directivas funcionan solo porque el script terminó. Necesitamos una herramienta que audite el estado real del kernel y de las cuentas. Por eso, en el paso 4 ejecutaremos nuestro script de auditoría integral."*

---

### 4. Auditoría Integral del Sistema (Paso 4 del README) (02:45 - 03:45)
* **Comandos en consola:**
  ```bash
  sudo ./scripts/verify_system.sh check
  ```
* **Qué decir:**
  > "Corremos el paso 4: `sudo ./scripts/verify_system.sh check`.  
  > Miren la pantalla, esta herramienta concentra en una sola vista toda la evidencia técnica:  
  > En la sección 1 validamos el **aislamiento de directorios**: todas las carpetas en `/home` muestran `drwxr-x--- (750)`, demostrando que un usuario de Operaciones no tiene forma de leer el home de Finanzas.  
  > En la sección 2 auditamos el **envejecimiento de credenciales** con `chage -l`. Observen que dice: 'Último cambio de contraseña: se debe cambiar la contraseña' y muestra la fecha exacta en que caduca la cuenta.  
  > En la sección 3 revisamos la tabla de `faillock` para verificar los registros de intentos fallidos.  
  > Y en las secciones 4 y 5 confirmamos la regla de sudoers con logs dedicados y las restricciones horarias activas en `time.conf`."

---

### 🟢 Conexión hacia el Paso 5:
> *"Ya comprobamos que los usuarios existen, que las directivas están activas y que el sistema está auditado. Pero la administración de servidores también exige saber qué hacer ante contingencias: ¿cómo congelamos a un empleado que deja la empresa o cómo desbloqueamos a un usuario que se equivocó de clave? Eso es lo que probaremos en el paso 5 final."*

---

### 5. Desaprovisionamiento Seguro y Desbloqueo (Paso 5 del README) (03:45 - 04:30)
* **Comandos en consola:**
  ```bash
  sudo ./scripts/deprovision_users.sh -l mariana.solis
  sudo ./scripts/verify_system.sh unlock luis.torres
  ```
* **Qué decir:**
  > "Concluimos con el paso 5. Primero simulamos la baja o suspensión controlada de un empleado con: `sudo ./scripts/deprovision_users.sh -l mariana.solis`.  
  > El parámetro `-l` realiza un 'soft lock': termina cualquier proceso que el usuario tenga corriendo en segundo plano con `pkill`, bloquea la contraseña y cambia su shell a `/sbin/nologin`. Con esto el usuario queda fuera del servidor al instante, pero sus archivos quedan intactos para cualquier auditoría.  
  > Y si en el día a día un usuario legítimo como Luis Torres bloquea su cuenta por escribir mal su clave tres veces, el administrador no tiene que esperar a que expire el tiempo; simplemente ejecuta: `sudo ./scripts/verify_system.sh unlock luis.torres`, lo cual restablece a cero los contadores de `faillock` y le devuelve el acceso de inmediato.  
  > Con esta demostración práctica cubrimos todos los requerimientos de la Tarea 3.1. Todos los scripts, configuraciones y el manual técnico en PDF se encuentran en el repositorio de GitHub. ¡Muchas gracias por acompañarme en este video!"
