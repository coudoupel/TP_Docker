BACKUP_DIR="/path/to/backup/directory"
DATE=$(date +\%Y\%m\%d\%H\%M\%S)
BACKUP_NAME="docker_volume_backup_$DATE.tar.gz"

# Liste des volumes Docker à sauvegarder
VOLUMES=$(docker volume ls -q)

# Crée un fichier de sauvegarde tar.gz
docker run --rm -v $VOLUMES:/volumes -v $BACKUP_DIR:/backup busybox tar czf /backup/$BACKUP_NAME -C /volumes .

# Affiche un message de confirmation
echo "Sauvegarde effectuée avec succès. Fichier de sauvegarde : $BACKUP_DIR/$BACKUP_NAME"
