# GUION PARA VIDEO: TAREA 3.3
**Materia:** Administración de Servidores  
**Carrera:** Ingeniería en Informática  
**Tema:** Configuración de almacenamiento redundante (RAID/NAS) y colas de impresión  
**Requisito indispensable:** Cámara web visible en la **esquina inferior derecha** todo el tiempo.  
**Duración estimada:** ~4 a 5 minutos (demostrativo, conectado y con explicaciones de hardware/servicios).

---

## 📌 Contexto inicial antes de grabar:
* Tener la terminal abierta en la carpeta de la práctica:
  ```bash
  cd ~/Administracion-De-Servidores-U3/Unidad_3/Tarea_3.3/
  ```
* En este video ejecutaremos en orden exacto los comandos de las **Instrucciones Rápidas de Ejecución del README**:
  1. `chmod +x scripts/*.sh`
  2. `sudo ./scripts/setup_raid.sh /dev/sdb /dev/sdc /dev/sdd`
  3. `sudo ./scripts/setup_samba.sh`
  4. `sudo ./scripts/setup_cups.sh setup`
  5. `sudo ./scripts/setup_cups.sh test-print`
  6. `sudo ./scripts/raid_fail_simulate.sh fail`
  7. `sudo ./scripts/raid_fail_simulate.sh rebuild /dev/sdb`

---

## 🎬 Minuto a Minuto del Video

### 1. Introducción y Contexto (00:00 - 00:45)
* **Qué hacer en pantalla:** Terminal limpia con la cámara web activa en la esquina inferior derecha.
* **Qué decir:**
  > "Qué tal a todos, mi nombre es [Tu Nombre], estudiante de la carrera de Ingeniería en Informática, y este video corresponde a la Tarea 3.3 de la Unidad 3 en la materia de Administración de Servidores.  
  > En esta práctica final integraremos tres componentes esenciales de la infraestructura de red: alta disponibilidad en almacenamiento mediante RAID 5 por software, recursos compartidos en red con Samba y administración de colas de impresión periféricas mediante CUPS.  
  > Como contexto fundamental de nuestra arquitectura: estamos utilizando una máquina virtual con Debian Server en VMware Workstation. La enorme ventaja de utilizar un entorno virtualizado aquí es que pudimos agregar tres discos duros virtuales independientes de 2 GB cada uno (`sdb`, `sdc` y `sdd`). Esto nos permite construir un arreglo RAID real por software y simular la desconexión física de un disco en caliente sin ningún riesgo para los componentes físicos de nuestra computadora.  
  > Vamos a comenzar ejecutando en orden los comandos de la guía rápida del README."

---

### 2. Permisos y Despliegue del Arreglo RAID 5 (Paso 1 y 2 del README) (00:45 - 01:50)
* **Comandos en consola:**
  ```bash
  chmod +x scripts/*.sh
  sudo ./scripts/setup_raid.sh /dev/sdb /dev/sdc /dev/sdd
  ```
* **Qué decir:**
  > "Primero habilitamos los permisos de ejecución en los scripts con `chmod +x scripts/*.sh`.  
  > Ahora procedemos con el paso 2: construir y montar nuestro arreglo redundante ejecutando: `sudo ./scripts/setup_raid.sh /dev/sdb /dev/sdc /dev/sdd`.  
  > Expliquemos qué ocurre tras bambalinas:  
  > El script invoca la utilidad del kernel **`mdadm`** para agrupar nuestros tres discos en el dispositivo virtual `/dev/md0` bajo el nivel **RAID 5**.  
  > ¿Por qué RAID 5? Porque combina rendimiento y tolerancia a fallos mediante **paridad distribuida**. La capacidad utilizable sigue la fórmula matemática $(N - 1) \times \text{Tamaño}$: como tenemos tres discos de 2 GB, obtenemos casi 4 GB disponibles y 2 GB dedicados a bloques de paridad.  
  > Luego, el script le da formato al volumen con el sistema de archivos `ext4`, lo monta en el directorio `/mnt/almacen_redundante` y asegura su persistencia en `/etc/fstab`.  
  > En la salida de `/proc/mdstat` vemos la bandera clave **`[3/3] [UUU]`**, lo que confirma que los tres miembros están activos y sincronizados."

---

### 🟢 Conexión hacia el Paso 3:
> *"Ahora que ya contamos con un volumen de almacenamiento de alta disponibilidad protegido contra fallos de disco, el siguiente objetivo es ponerlo al servicio de la organización. Necesitamos que las diferentes áreas de la empresa puedan guardar y consultar archivos en red sobre este RAID. Por eso, en el paso 3 desplegaremos un servidor NAS mediante Samba."*

---

### 3. Servicio de Almacenamiento en Red (NAS Samba) (Paso 3 del README) (01:50 - 02:40)
* **Comandos en consola:**
  ```bash
  sudo ./scripts/setup_samba.sh
  ```
* **Qué decir:**
  > "Ejecutamos el paso 3: `sudo ./scripts/setup_samba.sh`.  
  > Con este script levantamos un servidor de almacenamiento en red (**NAS**) utilizando el protocolo SMB/CIFS a través de Samba.  
  > El script aplica nuestra plantilla `smb.conf`, valida la sintaxis con `testparm` y activa las contraseñas de red para los usuarios departamentales que creamos en la primera práctica, como Carlos Mendoza de Sistemas o Ana Morales de Finanzas.  
  > Lo más importante aquí es que el recurso compartido `[AlmacenRAID]` apunta directamente a la ruta `/mnt/almacen_redundante`. Esto significa que cualquier archivo que los usuarios de Windows o Linux guarden en la carpeta compartida se escribirá con redundancia de bloques en el RAID, protegiendo la información de la empresa de forma transparente."

---

### 🟢 Conexión hacia el Paso 4:
> *"Además del almacenamiento centralizado, una red corporativa requiere gestionar periféricos compartidos para evitar cuellos de botella en la oficina. En el paso 4 configuraremos un servidor de impresión con colas diferenciadas por prioridad utilizando el estándar CUPS."*

---

### 4. Servidor de Impresión CUPS y Prioridades (Paso 4 del README) (02:40 - 03:30)
* **Comandos en consola:**
  ```bash
  sudo ./scripts/setup_cups.sh setup
  sudo ./scripts/setup_cups.sh test-print
  ```
* **Qué decir:**
  > "Corremos el paso 4 para inicializar el servidor de impresión: `sudo ./scripts/setup_cups.sh setup`.  
  > CUPS (Common UNIX Printing System) se despliega escuchando peticiones en red TCP/IP a través del puerto estándar **631**.  
  > En lugar de una sola cola general, creamos dos colas compartidas: `Cola_Estandar` para impresiones cotidianas de ofimática y `Cola_Urgente` para documentos prioritarios como facturas o contratos de Dirección.  
  > Ahora ejecutamos la prueba técnica: `sudo ./scripts/setup_cups.sh test-print`.  
  > El script envía dos trabajos concurrentes: uno con prioridad normal (valor 20) a la cola estándar y otro con prioridad alta (valor 100) a la cola urgente. Mediante `lpstat -o` comprobamos cómo el despachador de CUPS procesa y prioriza los documentos en red de acuerdo con las directivas de negocio."

---

### 🟢 Conexión hacia el Paso 5:
> *"Para cerrar nuestra práctica, regresamos al componente más crítico: el arreglo redundante. Todo el diseño de RAID 5 promete que si un disco duro físico se destruye o se desconecta, la empresa puede seguir trabajando sin interrupción. En el paso 5 pondremos a prueba esta promesa induciendo una avería en caliente y realizando la reconstrucción del disco."*

---

### 5. Simulación de Falla y Reconstrucción en Caliente (Paso 5 del README) (03:30 - 04:30)
* **Comandos en consola:**
  ```bash
  sudo ./scripts/raid_fail_simulate.sh fail
  sudo ./scripts/raid_fail_simulate.sh rebuild /dev/sdb
  ```
* **Qué decir:**
  > "Concluimos con el paso 5. Primero inducimos la avería del disco `/dev/sdb` con: `sudo ./scripts/raid_fail_simulate.sh fail`.  
  > Observen con atención `/proc/mdstat`: el disco `sdb` pasa a estado 'faulty' marcado con una `(F)` y el arreglo entra en **estado degradado**: vemos la bandera **`[3/2] [_UU]`**.  
  > Lo impresionante de RAID 5 es que, a pesar de que un disco está averiado, los servicios como Samba y el punto de montaje siguen 100% operativos; nadie pierde el acceso porque el kernel recalcula al vuelo los datos faltantes utilizando los bloques de paridad de los otros discos sanos.  
  > Ahora simulamos que el técnico en el centro de datos reemplaza la unidad por un disco nuevo y forzamos la recuperación con: `sudo ./scripts/raid_fail_simulate.sh rebuild /dev/sdb`.  
  > El script retira el disco defectuoso, inserta el repuesto y el subsistema `md` comienza de inmediato el proceso de **Hot Rebuild** o sincronización en caliente. Al finalizar, el arreglo retorna al estado óptimo: **`[3/3] [UUU]`**, todo sin haber tenido que reiniciar ni apagar el servidor.  
  > Con esta demostración completa cubrimos al 100% los requerimientos de la Tarea 3.3 y finalizamos las actividades de la Unidad 3 de Administración de Servidores. ¡Muchas gracias por ver el video!"
