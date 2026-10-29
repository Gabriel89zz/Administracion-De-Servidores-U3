# GUION TÉCNICO PARA GRABACIÓN DE VIDEO: TAREA 3.3
**Plataforma de entrega:** YouTube (Enlace Público / Oculto)  
**Requisito de Rúbrica:** Cámara web visible y activa en la **esquina inferior derecha** durante toda la grabación.  
**Duración recomendada:** Entre 5 y 7 minutos.  
**Resolución recomendada:** 1080p (1920x1080), tamaño de fuente de terminal de 16pt o superior.

---

## Checklist Previo a la Grabación

1. [ ] Cámara web configurada en OBS Studio en la **esquina inferior derecha**.
2. [ ] Arreglo RAID creado y montado con los discos de VMware: `sudo ./scripts/setup_raid.sh /dev/sdb /dev/sdc /dev/sdd`.
3. [ ] Samba desplegado: `sudo ./scripts/setup_samba.sh`.
4. [ ] CUPS configurado y activo: `sudo ./scripts/setup_cups.sh setup`.
5. [ ] Terminal con pestañas o ventanas limpias y legibles.

---

## Estructura Cronológica del Video

```
00:00 - 00:45 | Introducción, presentación personal y objetivos de la Tarea 3.3
00:45 - 02:00 | Inspección del Arreglo RAID 5 en Estado Óptimo (mdadm --detail)
02:00 - 03:00 | Verificación del Almacenamiento Compartido en Red (Samba/NAS)
03:00 - 04:15 | Simulación de Desconexión de Disco y Estado Degradado ([_UU])
04:15 - 05:15 | Reemplazo de Disco y Monitoreo de Reconstrucción en Caliente (Rebuild)
05:15 - 06:30 | Demostración del Servidor de Impresión CUPS y Prueba de Impresión en Red
06:30 - 07:00 | Conclusiones Generales y Cierre
```

---

## Escena 1: Introducción y Presentación (00:00 - 00:45)
* **Visual:** Terminal despejada, cámara web en la esquina inferior derecha.
* **Locución (Qué decir):**
  > *"Hola a todos, mi nombre es [Tu Nombre], estudiante de la materia Administración de Servidores. En esta última entrega demostraremos la Tarea 3.3: Configuración de almacenamiento redundante mediante RAID por software, montaje de una unidad compartida en red mediante Samba y la puesta en marcha de un servidor de impresión corporativo con CUPS sobre Debian GNU/Linux.*  
  > *Veremos en directo la resiliencia del sistema simulando la pérdida física de un disco, su reconstrucción en caliente sin pérdida de servicio y pruebas de envío de trabajos con diferentes prioridades de impresión."*

---

## Escena 2: Inspección de Discos y Estado del RAID (00:45 - 02:00)
* **Visual:** Ejecutar comandos de discos y estado del RAID.
* **Comandos a teclear:**
  ```bash
  lsblk
  cat /proc/mdstat
  sudo mdadm --detail /dev/md0
  df -h /mnt/almacen_redundante
  ```
* **Locución (Qué decir):**
  > *"Comenzamos revisando los dispositivos de almacenamiento con lsblk. Podemos observar nuestros discos de VMware: sda para el sistema base, y sdb, sdc y sdd que conforman nuestro arreglo RAID.*  
  > *Al consultar /proc/mdstat vemos que el dispositivo /dev/md0 está activo bajo RAID 5 con 3 discos sincronizados, indicado por la bandera [3/3] [UUU].*  
  > *Con mdadm --detail confirmamos el estado 'clean' y un volumen montado en /mnt/almacen_redundante listo para tolerar fallos."*

---

## Escena 3: Almacenamiento Compartido en Red (Samba) (02:00 - 03:00)
* **Visual:** Mostrar configuración de Samba y probar acceso local.
* **Comandos a teclear:**
  ```bash
  cat configs/smb.conf | grep -A 8 '\[AlmacenRAID\]'
  sudo smbclient -L localhost -N
  ```
* **Locución (Qué decir):**
  > *"Sobre este volumen de alta disponibilidad levantamos un servidor NAS mediante Samba. En la configuración de smb.conf, el recurso compartido 'AlmacenRAID' apunta directamente a la carpeta montada sobre el RAID, garantizando que todos los archivos que los usuarios de los departamentos almacenen cuenten con redundancia a nivel de bloques.*  
  > *Al listar los recursos con smbclient comprobamos que tanto la unidad AlmacenRAID como el área Pública están disponibles para cualquier cliente Windows o Linux de la red."*

---

## Escena 4: Simulación de Desconexión de Disco y Estado Degradado (03:00 - 04:15)
* **Visual:** Provocar la falla con el script y observar `/proc/mdstat`.
* **Comandos a teclear:**
  ```bash
  sudo ./scripts/raid_fail_simulate.sh fail
  cat /proc/mdstat
  sudo mdadm --detail /dev/md0
  # Demostrar que los datos siguen accesibles:
  ls -lh /mnt/almacen_redundante/
  ```
* **Locución (Qué decir):**
  > *"Ahora simularemos la avería o desconexión imprevista de uno de los discos del arreglo utilizando nuestro script de simulación.*  
  > *Noten de inmediato la salida de /proc/mdstat: el disco sdb ha pasado a estado faulty '(F)' y el arreglo cambia a modo DEGRADADO: [3/2] [_UU].*  
  > *Lo extraordinario de RAID 5 es que, a pesar de que el disco sdb está averiado, listamos /mnt/almacen_redundante y los archivos siguen totalmente intactos y disponibles. El kernel Linux recalcula en tiempo real los datos faltantes a partir de la paridad de sdc y sdd."*

---

## Escena 5: Reemplazo y Reconstrucción en Caliente (Hot Rebuild) (04:15 - 05:15)
* **Visual:** Retirar disco malo, insertar nuevo disco y ver la barra de sincronización.
* **Comandos a teclear:**
  ```bash
  sudo ./scripts/raid_fail_simulate.sh remove
  sudo ./scripts/raid_fail_simulate.sh rebuild
  cat /proc/mdstat
  ```
* **Locución (Qué decir):**
  > *"Para restablecer la salud del servidor, retiramos de forma lógica el disco dañado con --remove e insertamos una unidad de reemplazo con --add.*  
  > *Observen la consola: el subsistema md inicia de inmediato la reconstrucción o 'recovery' en caliente. La paridad se recalcula y se escribe en el nuevo miembro. Al completarse la barra de progreso al 100%, el arreglo retorna al estado 'clean' con sus 3 miembros activos [UUU], todo esto sin haber apagado el servidor ni un solo segundo."*

---

## Escena 6: Servidor de Impresión CUPS y Prioridades (05:15 - 06:30)
* **Visual:** Estado de colas con `lpstat` y prueba de impresión con `setup_cups.sh test-print`.
* **Comandos a teclear:**
  ```bash
  lpstat -p -d
  sudo ./scripts/setup_cups.sh test-print
  lpstat -o
  ```
* **Locución (Qué decir):**
  > *"Finalmente, pasamos al servidor de impresión periférica administrado por CUPS sobre el puerto TCP 631.*  
  > *Configuramos dos colas compartidas en red: Cola_Estandar para trabajos habituales y Cola_Urgente para documentos de alta prioridad.*  
  > *Ejecutamos nuestra prueba técnica: enviamos un primer trabajo con prioridad reducida 20 a la cola estándar, y un segundo trabajo con máxima prioridad 100 a la cola urgente.*  
  > *Con lpstat -o verificamos cómo el despachador de CUPS procesa y prioriza los documentos en red antes de convertirlos a PDF o enviarlos a la impresora física."*

---

## Escena 7: Conclusión General (06:30 - 07:00)
* **Visual:** Regreso a la terminal principal.
* **Locución (Qué decir):**
  > *"Con estas pruebas concluimos la totalidad de los requerimientos de la Unidad 3: automatizamos la identidad y seguridad de usuarios en la 3.1, gobernamos permisos POSIX, cuotas y respaldos en la 3.2, y logramos alta disponibilidad de almacenamiento con RAID, NAS y colas de impresión en la 3.3.*  
  > *Todos los scripts, configuraciones y manuales técnicos se encuentran disponibles en nuestro repositorio de GitHub. Muchas gracias por acompañarme en este video."*
