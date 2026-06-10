#!/bin/sh

# Configuración
ROUTER_USER="usr-backup-automation"
ROUTER_IP="10.10.40.1"
BACKUP_NAME="mikrotik_backup"
LOCAL_DIR="/backups"
DRIVE_REMOTE="gdrive-backup:"

DATE=$(date +%Y%m%d_%H%M%S)

echo "--- Iniciando respaldo de MikroTik ($DATE) ---"

# 1. Ordenar la generación de respaldos en el Router
echo "Generando respaldos en el router..."
ssh -i /app/.ssh/id_ed25519_backup -o StrictHostKeyChecking=no ${ROUTER_USER}@${ROUTER_IP} "/system backup save name=${BACKUP_NAME}; /export file=${BACKUP_NAME}"

# Esperar a que el almacenamiento termine de escribir los archivos
sleep 5

# 2. Descargar los archivos temporales al contenedor usando SCP
echo "Descargando archivos al almacenamiento local..."
scp -i /app/.ssh/id_ed25519_backup -o StrictHostKeyChecking=no ${ROUTER_USER}@${ROUTER_IP}:${BACKUP_NAME}.backup ${LOCAL_DIR}/${BACKUP_NAME}_${DATE}.backup
scp -i /app/.ssh/id_ed25519_backup -o StrictHostKeyChecking=no ${ROUTER_USER}@${ROUTER_IP}:${BACKUP_NAME}.rsc ${LOCAL_DIR}/${BACKUP_NAME}_${DATE}.rsc

# 3. Subir a Google Drive con rclone forzando parámetros de subida
echo "Sincronizando con Google Drive..."
rclone copy ${LOCAL_DIR}/ ${DRIVE_REMOTE} --include "${BACKUP_NAME}_${DATE}.*" --drive-upload-cutoff 0 -v

# 4. Limpieza del directorio temporal interno del contenedor
rm -f ${LOCAL_DIR}/${BACKUP_NAME}_${DATE}.*

echo "--- Respaldo completado exitosamente ---"
