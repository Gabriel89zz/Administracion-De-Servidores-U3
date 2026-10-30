# GUION PARA VIDEO: TAREA 3.3
**Materia:** Administración de Servidores  
**Carrera:** Ingeniería en Informática  
**Tema:** Almacenamiento redundante (RAID 5 / NAS Samba) y Servidor de impresión CUPS  
**Requisito indispensable:** Cámara web visible en la **esquina inferior derecha** todo el tiempo.  
**Duración objetivo:** ~3 a 4 minutos (dinámico y visual).

---

## Tips rápidos antes de grabar:
1. Revisa tu cámara en la esquina inferior derecha.
2. Abre la terminal en la carpeta de la Tarea 3.3:
   ```bash
   cd ~/Administracion-De-Servidores-U3/Unidad_3/Tarea_3.3/
   ```

---

## 🎬 Minuto a Minuto del Video

### 1. Introducción y Contexto (00:00 - 00:45)
* **Qué hacer en pantalla:** Terminal visible con la cámara activa abajo a la derecha.
* **Qué decir:**
  > "Qué tal a todos, mi nombre es [Tu Nombre], estudiante de Ingeniería en Informática en la materia de Administración de Servidores. En este video realizamos la demostración práctica de la Tarea 3.3 de la Unidad 3: almacenamiento redundante con RAID por software, unidad de red compartida con Samba y servidor de impresión con CUPS.  
  > Seguimos utilizando nuestra máquina virtual con Debian Server en VMware Workstation. Una de las grandes ventajas de usar una máquina virtual para esta práctica es que pudimos agregar 3 discos duros virtuales independientes de 2 GB cada uno para armar un RAID 5 real por software y simular la falla física de un disco en caliente sin peligro de dañar nuestro hardware real. Vamos a ver cómo funciona."

---

### 2. Discos de VMware y Estado del RAID 5 (00:45 - 01:30)
* **Comandos en consola:**
  ```bash
  lsblk
  cat /proc/mdstat
  df -h /mnt/almacen_redundante
  ```
* **Qué decir:**
  > "Primero ejecutamos `lsblk`. Aquí podemos ver nuestros discos virtuales agregados en VMware: `sda` donde vive el sistema operativo Debian, y `sdb`, `sdc` y `sdd` que son los 3 discos asignados a nuestro arreglo.  
  > Al consultar `/proc/mdstat` vemos que el dispositivo `/dev/md0` está activo bajo RAID 5 con los 3 miembros sincronizados, indicado por la bandera `[3/3] [UUU]`.  
  > Y con `df -h /mnt/almacen_redundante` comprobamos que el volumen formateado en ext4 está montado y listo con casi 4 Gigas utilizables, justo lo que dicta la fórmula de RAID 5: N menos un discos."

---

### 3. Unidad Compartida en Red con Samba (01:30 - 02:00)
* **Comandos en consola:**
  ```bash
  sudo ./scripts/setup_samba.sh
  ```
* **Qué decir:**
  > "Sobre este almacenamiento de alta disponibilidad montamos un servidor NAS usando Samba con `sudo ./scripts/setup_samba.sh`.  
  > El script valida la configuración con `testparm` y activa las credenciales de red para nuestros usuarios departamentales. De esta forma, el recurso compartido `AlmacenRAID` vive directamente sobre el arreglo redundante, protegiendo todos los archivos que los usuarios guarden en la red local."

---

### 4. Simulación de Falla de Disco y Reconstrucción en Caliente (02:00 - 03:00)
* **Comandos en consola:**
  ```bash
  sudo ./scripts/raid_fail_simulate.sh fail
  cat /proc/mdstat
  ls -la /mnt/almacen_redundante/
  sudo ./scripts/raid_fail_simulate.sh remove
  sudo ./scripts/raid_fail_simulate.sh rebuild /dev/sdb
  cat /proc/mdstat
  ```
* **Qué decir:**
  > "Ahora viene la prueba clave: ¿qué pasa si un disco se descompone?  
  > Simulamos la avería con `sudo ./scripts/raid_fail_simulate.sh fail`.  
  > Miren `/proc/mdstat`: el disco `sdb` pasa a estado faulty `(F)` y el arreglo entra en modo degradado: `[3/2] [_UU]`.  
  > Pero a pesar de que el disco falló, listamos `/mnt/almacen_redundante` y los archivos siguen 100% disponibles porque el kernel recalcula la paridad al vuelo.  
  > Para solucionarlo, retiramos el disco dañado con `remove` y ejecutamos `rebuild /dev/sdb`.  
  > El sistema inicia la reconstrucción en caliente y vuelve de inmediato al estado saludable `[3/3] [UUU]`, todo sin haber apagado el servidor ni un solo segundo."

---

### 5. Servidor de Impresión CUPS y Prioridades (03:00 - 03:45)
* **Comandos en consola:**
  ```bash
  sudo ./scripts/setup_cups.sh setup
  sudo ./scripts/setup_cups.sh test-print
  ```
  *(Opcional rápido: si tienes abierto el navegador en Windows con `http://192.168.1.175:631/printers/`, puedes cambiar de ventana un segundo para mostrarlo).*
* **Qué decir:**
  > "Por último, revisamos el servidor de impresión periférica con CUPS sobre el puerto TCP 631.  
  > Con `setup_cups.sh` creamos dos colas compartidas: `Cola_Estandar` y `Cola_Urgente`.  
  > Y al correr `test-print`, enviamos un trabajo con prioridad normal (valor 20) y otro con prioridad alta (valor 100). Con `lpstat -o` comprobamos cómo el despachador de CUPS procesa y prioriza los documentos en red de acuerdo a su urgencia.  
  > Con esto demostramos la alta disponibilidad en almacenamiento y servicios periféricos de red para la Tarea 3.3 y concluimos la Unidad 3 de Administración de Servidores. ¡Muchas gracias por su atención!"
