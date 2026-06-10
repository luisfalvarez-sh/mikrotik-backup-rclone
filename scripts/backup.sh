#!/bin/sh

# Configuración (Las variables se heredan del contenedor/.env)
LOCAL_DIR="/backups"
DATE=$(date +%Y%m%d_%H%M%S)

echo "--- Iniciando respaldo de MikroTik ($DATE) ---"

# 1. Ordenar la generación de respaldos en el Router
echo "Generando respaldos en el router..."
ssh -i /app/.ssh/id_ed25519_backup -o StrictHostKeyChecking=no ${ROUTER_USER}@${ROUTER_IP} "/system backup save name=${BACKUP_NAME}; /export file=${BACKUP_NAME}"

# Esperar a que el almacenamiento termine de escribir
sleep 5

# 2. Descargar los archivos temporales al contenedor usando SCP
echo "Descargando archivos al almacenamiento local..."
scp -i /app/.ssh/id_ed25519_backup -o StrictHostKeyChecking=no ${ROUTER_USER}@${ROUTER_IP}:${BACKUP_NAME}.backup ${LOCAL_DIR}/${BACKUP_NAME}_${DATE}.backup
scp -i /app/.ssh/id_ed25519_backup -o StrictHostKeyChecking=no ${ROUTER_USER}@${ROUTER_IP}:${BACKUP_NAME}.rsc ${LOCAL_DIR}/${BACKUP_NAME}_${DATE}.rsc

# 3. Subir a Google Drive
echo "Sincronizando con Google Drive..."
rclone copy ${LOCAL_DIR}/ ${DRIVE_REMOTE} --include "${BACKUP_NAME}_${DATE}.*" -v

# 4. Limpieza del directorio temporal interno
rm -f ${LOCAL_DIR}/${BACKUP_NAME}_${DATE}.*

echo "--- Respaldo completado exitosamente ---"
