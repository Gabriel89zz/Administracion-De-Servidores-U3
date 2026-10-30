# GUION PARA VIDEO: TAREA 3.1
**Materia:** Administración de Servidores  
**Carrera:** Ingeniería en Informática  
**Tema:** Automatización de administración de usuarios, grupos y políticas de acceso  
**Requisito indispensable:** Cámara web visible en la **esquina inferior derecha** todo el tiempo.  
**Duración objetivo:** ~3 a 4 minutos (dinámico, al grano y sin rollos largos).

---

## Tips rápidos antes de grabar:
1. Revisa que tu OBS o grabador tenga tu cámara en la esquina inferior derecha.
2. Ten la terminal lista en la carpeta de la práctica:
   ```bash
   cd ~/Administracion-De-Servidores-U3/Unidad_3/Tarea_3.1/
   ```
3. Si la VM ya tenía usuarios creados, recuerda revertir al snapshot limpio de VMware antes de darle "Rec".

---

## 🎬 Minuto a Minuto del Video

### 1. Introducción y Contexto (00:00 - 00:45)
* **Qué hacer en pantalla:** Terminal visible con la cámara activa abajo a la derecha. Puedes mostrar un `cat /etc/os-release` rápido o dejar la terminal limpia.
* **Qué decir:**
  > "Qué tal a todos, mi nombre es [Tu Nombre], estudiante de la carrera de Ingeniería en Informática, y este video es para la materia de Administración de Servidores.  
  > En esta práctica vamos a ver la Tarea 3.1 de la Unidad 3, enfocada en la gestión automatizada de usuarios, grupos y políticas de seguridad.  
  > Como contexto rápido: estamos trabajando sobre una máquina virtual con Debian Server montada en VMware Workstation. Usamos una máquina virtual porque nos da un entorno aislado y seguro donde podemos aplicar directivas críticas del sistema operativo, manipular PAM, sudoers y particiones sin poner en riesgo nuestro equipo principal de uso diario, además de que nos permite simular el comportamiento real de un servidor empresarial dedicado.  
  > Así que vamos a darle directo a las pruebas en consola."

---

### 2. Creación Masiva de Usuarios por Lotes (00:45 - 01:45)
* **Comandos en consola:**
  ```bash
  cat scripts/usuarios.csv
  sudo ./scripts/provision_users.sh scripts/usuarios.csv
  ```
* **Qué decir:**
  > "Primero les muestro nuestro archivo `usuarios.csv`. Aquí tenemos definidos los usuarios divididos en áreas departamentales como Sistemas, Finanzas, Operaciones y Dirección, cada uno con una contraseña temporal y su fecha de expiración.  
  > Ahora ejecutamos el script de aprovisionamiento masivo: `sudo ./scripts/provision_users.sh scripts/usuarios.csv`.  
  > Como pueden ver, el script lee el archivo, crea automáticamente los grupos si no existían, da de alta a cada usuario con `useradd`, inyecta la contraseña temporal y además le aplica la directiva `chage -d 0` para obligarlos a cambiar su clave la primera vez que inicien sesión. También aplica permisos 750 a cada carpeta home."

---

### 3. Aislamiento de Homes y Cambio Forzado de Clave (01:45 - 02:30)
* **Comandos en consola:**
  ```bash
  ls -ld /home/*
  su - carlos.mendoza
  ```
  *(Ingresas la contraseña temporal `TempPassTI2026!`. El sistema te pedirá cambiarla de inmediato; pon una nueva clave, dale Enter y escribe `exit`).*
* **Qué decir:**
  > "Si listamos `/home` con `ls -ld /home/*`, vemos que todos los directorios tienen permisos `drwxr-x---`, es decir, modo 750. Esto significa que ningún usuario de un departamento puede entrar a husmear en los archivos de otro.  
  > Y para probar la expiración de credenciales, iniciamos sesión como `carlos.mendoza`. Introducimos su contraseña temporal y el sistema de inmediato nos frena y nos exige cambiarla: 'You are required to change your password immediately'. Hasta que no definimos una contraseña nueva no nos deja trabajar. Salimos con `exit`."

---

### 4. Directivas de Seguridad: Sudoers, PAM y Desbloqueo (02:30 - 03:30)
* **Comandos en consola:**
  ```bash
  sudo ./scripts/apply_security.sh
  sudo ./scripts/verify_system.sh check
  ```
* **Qué decir:**
  > "Ahora aplicamos las directivas de seguridad con `sudo ./scripts/apply_security.sh`. Esto configura tres cosas clave:  
  > Uno: control de sudoers delegado al grupo 'sistemas' con logs auditados en `/var/log/sudo_sistemas.log`.  
  > Dos: control de horarios con `pam_time`, para que usuarios de Finanzas y Operaciones solo puedan acceder en horario laboral.  
  > Tres: protección contra ataques de fuerza bruta con `pam_faillock`.  
  > Para comprobar que todo quedó bien, corremos nuestra herramienta de auditoría: `sudo ./scripts/verify_system.sh check`.  
  > Aquí vemos en un solo vistazo el aislamiento de directorios, las fechas de caducidad con `chage` y las políticas activas de PAM."

---

### 5. Cierre Rápido (03:30 - 03:50)
* **Qué decir:**
  > "Como demostración final, si requerimos dar de baja o congelar a un usuario de forma segura, contamos con `deprovision_users.sh`, que permite suspender la cuenta o respaldar su directorio home antes de borrarlo.  
  > Con esto cubrimos al 100% los requisitos de la Tarea 3.1. Todos los scripts y la documentación están en el repositorio de GitHub. ¡Muchas gracias por ver el video!"
