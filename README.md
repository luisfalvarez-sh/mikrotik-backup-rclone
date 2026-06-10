# 🚀 MikroTik Automated Backup Pipeline (Docker + Rclone)

Un pipeline ultraligero y seguro, basado en contenedores, para automatizar el respaldo diario de routers MikroTik (RouterOS v7) hacia Google Drive.

Este proyecto resuelve desafíos técnicos comunes en la administración de redes modernas, como los estrictos permisos de exportación no interactiva en RouterOS v7, el manejo del PID 1 en contenedores Alpine para tareas Cron, y las restricciones de cuota de la API de Google Drive para Service Accounts.

## ✨ Características Principales

* 🔒 **Arquitectura Zero-Trust:** Utiliza llaves criptográficas Ed25519 y un usuario de sistema en RouterOS estrictamente anclado (IP-Binding) a la IP del contenedor.
* 🐳 **Eficiencia Dockerizada:** Basado en la imagen oficial de Alpine Linux de Rclone. No requiere la construcción de imágenes personalizadas (`Dockerfile`), operando al vuelo mediante `entrypoint` inyectado.
* ☁️ **Bypass de Cuotas en Google Drive:** Implementa autenticación OAuth personal (`client_id` + `client_secret`) para saltar el error `403 storageQuotaExceeded` de las Service Accounts en carpetas compartidas.
* 🕒 **Cron Sincronizado:** Demonio `crond` ejecutándose limpiamente bajo el PID 1 del contenedor, con inyección directa de zona horaria local (`TZ`) para ejecuciones de madrugada precisas.
* 🧹 **Stateless & Clean:** Genera, descarga, sube y elimina los archivos binarios (`.backup`) y de texto plano (`.rsc`) en una misma transacción. No deja almacenamiento residual en el host.

---

## 🛠️ Requisitos Previos

1. Docker y Docker Compose instalados en el host.
2. Un router MikroTik corriendo RouterOS v7.
3. Credenciales de Rclone (OAuth) generadas para Google Drive.

---

## 🚀 Instalación y Despliegue

### 1. Clonar el repositorio
```bash
git clone [https://github.com/tu-usuario/mikrotik-backup-rclone.git](https://github.com/tu-usuario/mikrotik-backup-rclone.git)
cd mikrotik-backup-rclone
```

### 2. Estructura de secretos (Ignorados en Git)
Por seguridad, debes crear manualmente las carpetas para tus llaves SSH y configuraciones locales:
```bash
mkdir -p config .ssh temp_backups
```

### 3. Configurar variables de entorno
Crea un archivo `.env` en la raíz (puedes basarte en este ejemplo):
```ini
ROUTER_USER=usr-backup-automation
ROUTER_IP=10.10.40.1
BACKUP_NAME=mikrotik_backup
DRIVE_REMOTE=gdrive-backup:
```

### 4. Generar la llave SSH
Genera una llave sin contraseña y colócala en el directorio `.ssh/`. Aplica políticas de Mínimo Privilegio:
```bash
ssh-keygen -t ed25519 -f .ssh/id_ed25519_backup -N ""
chmod 700 .ssh
chmod 600 .ssh/id_ed25519_backup
```
*Asegúrate de agregar la llave pública (`.pub`) a tu MikroTik.*

### 5. Configurar Rclone
Crea el archivo `config/rclone.conf` con tus parámetros OAuth:
```ini
[gdrive-backup]
type = drive
client_id = TU_CLIENT_ID
client_secret = TU_CLIENT_SECRET
scope = drive
token = {"access_token":"..."}
root_folder_id = TU_FOLDER_ID
```

### 6. Levantar la infraestructura
```bash
docker compose up -d
```
El contenedor se ensamblará, instalará las dependencias necesarias (`openssh-client`, `tzdata`), inyectará el crontab y quedará a la espera de las 03:00 AM.

---

## 🧠 Technical Deep Dive (Retos Superados)

Este repositorio está diseñado superando tres obstáculos técnicos clave:

1. **El error `not enough permissions (9)` en RouterOS v7:**
   Para que un script externo pueda ejecutar `/system backup save` de forma no interactiva (background), el usuario en v7 exige permisos de lectura/escritura a nivel de sistema. Se mitigó asignando el grupo `full`, pero neutralizando el riesgo de seguridad al forzar la política `address=IP_DEL_CONTENEDOR`.

2. **El error `403 Service Accounts do not have storage quota` en Google Drive:**
   Las cuentas de Google personales prohíben a las Cuentas de Servicio (Service Accounts) heredar espacio de almacenamiento. Este pipeline utiliza tokens OAuth delegados para forzar a la API a usar el espacio nativo del usuario, permitiendo la copia directa de Rclone sin trabas.

3. **El colapso silencioso del PID 1 en Alpine Linux:**
   En Docker Compose, el uso de pipes multilínea (`|`) para el `command` a menudo concatena parámetros de manera errónea, provocando que el demonio `crond` nunca inicie. Se resolvió estructurando explícitamente los operadores lógicos `&& exec crond -f -l 2`, garantizando que Cron asuma el control como proceso principal ininterrumpido.

---

## 🤝 Contribuciones
Si tienes ideas para optimizar el consumo de recursos o añadir soporte para notificaciones vía Webhook (ej. Telegram/Discord tras la ejecución del script), siéntete libre de abrir un Pull Request.
