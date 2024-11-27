BACKUP_DIR="/path/to/backup/directory"
BACKUP_FILE="docker_volume_backup_YYYYMMDDHHMMSS.tar.gz"

# Création d'un conteneur temporaire pour restaurer la sauvegarde
docker run --rm -v $BACKUP_DIR:/backup -v /var/lib/docker/volumes:/volumes busybox tar xzf /backup/$BACKUP_FILE -C /volumes
