# Administración de Servidores - Prácticas Unidad 3: Gestión del Servidor

**Competencia específica:**  
> Conoce, configura y gestiona usuarios, sistemas de archivos y dispositivos mediante el uso de la interfaz gráfica y línea de comandos para el sistema operativo.

* **Sistema Operativo:** Debian Server 12 (Bookworm) / 64-bit
* **Entorno de Pruebas:** Máquina Virtual (VirtualBox / VMware)
* **Estudiante:** Hector Gabriel Torres Arzola
* **Matrícula / ID:** I23050363
* **Docente / Asignatura:** Administración de Servidores

---

## Tabla de Contenidos y Entregables

| Tarea | Descripción | Código & Scripts | Documento Técnico | Video en YouTube |
| :--- | :--- | :--- | :--- | :--- |
| **Tarea 3.1** | Automatización de usuarios, grupos y directivas de seguridad | [Scripts 3.1](./Unidad_3/Tarea_3.1/scripts/) | [Manual Técnico 3.1 (Markdown)](./Unidad_3/Tarea_3.1/docs/Manual_Tecnico_3.1.md) | [Ver en YouTube (Pendiente Enlace)](#) |
| **Tarea 3.2** | Permisos avanzados (SGID/Sticky/ACLs), Cuotas y Respaldos | [Scripts 3.2](./Unidad_3/Tarea_3.2/scripts/) | [Reporte Técnico 3.2 (Markdown)](./Unidad_3/Tarea_3.2/docs/Reporte_Tecnico_3.2.md) | [Ver en YouTube (Pendiente Enlace)](#) |
| **Tarea 3.3** | Almacenamiento redundante (RAID/NAS) y Colas de Impresión (CUPS) | [Scripts 3.3](./Unidad_3/Tarea_3.3/scripts/) | [Reporte Técnico 3.3 (Markdown)](./Unidad_3/Tarea_3.3/docs/Reporte_Tecnico_3.3.md) | [Ver en YouTube (Pendiente Enlace)](#) |

---

## Estructura del Repositorio

```text
.
├── .gitignore
├── README.md                                  <- Índice general y tabla de entregables
└── Unidad_3/
    ├── Tarea_3.1/                             <- Identidad, PAM, Sudoers y Scripts Batch
    │   ├── scripts/
    │   │   ├── usuarios.csv                   <- Archivo delimitado para aprovisionamiento
    │   │   ├── provision_users.sh             <- Altas masivas, expiración y contraseñas
    │   │   ├── deprovision_users.sh           <- Bajas seguras y resguardo de datos
    │   │   ├── apply_security.sh              <- Configuración de pam_faillock, pam_time y sudoers
    │   │   └── verify_system.sh               <- Script de comprobación y auditoría rápida
    │   ├── docs/
    │   │   ├── Manual_Tecnico_3.1.md          <- Manual con tablas, diagramas y capturas
    │   │   └── GUION_VIDEO_3.1.md             <- Guion detallado para grabación en YouTube
    │   └── README.md                          <- Instrucciones de ejecución Tarea 3.1
    ├── Tarea_3.2/                             <- Permisos SGID, Sticky bit, ACLs, Cuotas y Backup
    └── Tarea_3.3/                             <- RAID por software, Samba y Servidor de Impresión
```

---

## Requisitos de Entorno de Ejecución

Para reproducir las demostraciones y ejecutar los scripts:
1. Máquina virtual Debian GNU/Linux 11 o 12.
2. Acceso con privilegios de superusuario (`root` o vía `sudo`).
3. Paquetes requeridos instalados:
   ```bash
   sudo apt update
   sudo apt install -y sudo libpam-modules libpam-faillock passwd acl quota rsync tar mdadm samba cups
   ```
