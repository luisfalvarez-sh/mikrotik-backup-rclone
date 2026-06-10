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
