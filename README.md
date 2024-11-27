# TP_DOCKER  
## Mise en place de la solution  
Pour réaliser ce projet, l'environnement devra être réaliser comme tel:  
  
- Création d'une VM Debian 12  
- Installation de Docker 
  
Pour ce projet, j'ai décider de mettre en place GLPI, un logiciel libre de gestion des services informatiques et d'assistance.  
  
Je vais monter 3 conteneur pour ma solution :  
  
- Un nginx qui servira de frontend  
- GLPI qui servira de backend  
- Mariadb qui servira de base de données  
### Schéma simplifié :  
[![Image](https://i.goopics.net/5tm3gk.png)](https://goopics.net/i/5tm3gk)

#### Frontend(Nginx)
- **Rôle principal** : Sert de passerelle d'entrée.

  -   Reçoit les requêtes des utilisateurs via le navigateur (HTTP/HTTPS).
  -   Redirige ces requêtes vers le backend (`glpi`) via un proxy inversé.

#### Backend (GLPI)

-   **Rôle principal** : Gère la logique de l'application.
    -   Analyse les requêtes envoyées par Nginx (par exemple, pour afficher une page, enregistrer un ticket, ou charger des données).
    -   Communique avec la base de données (`db`) pour lire/écrire les données nécessaires.
 #### Base de données (MariaDB)

-   **Rôle principal** : Stocke les données de l'application de manière persistante.
    -   Contient les informations des utilisateurs, tickets, configurations, etc.
    -   Traite uniquement les requêtes SQL envoyées par le backend (GLPI).

  
Ces conteneurs seront créer à partir d'un fichier docker-compose.yml qui pourra par la suite être exécuter.
  
### Description du fichier docker-compose.yml :  
```bash  
version: '3.9'

services:
  glpi:
    image: diouxx/glpi:latest
    container_name: glpi
    restart: unless-stopped
    networks:
      - public_network
      - private_network
    environment:
      GLPI_DB_HOST: db
      GLPI_DB_NAME: bdd_glpi
      GLPI_DB_USER: user1
      GLPI_DB_PASSWORD: donttouchmydb
    depends_on:
      - db

  db:
    image: mariadb:latest
    container_name: bdd_glpi
    restart: unless-stopped
    volumes:
      - db_data:/var/lib/mysql
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword
      MYSQL_DATABASE: bdd_glpi
      MYSQL_USER: user1
      MYSQL_PASSWORD: donttouchmydb
    networks:
      - private_network

  nginx:
    image: nginx:latest
    container_name: nginx
    restart: unless-stopped
    ports:
      - "8085:80" # Expose Nginx uniquement sur le port 8085
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    networks:
      - public_network
    depends_on:
      - glpi

volumes:
  db_data:

networks:
  public_network:
    driver: bridge
  private_network:
    driver: bridge
  
```  
### Expliquation du fichier:  
Nos 3 conteneurs sont représentés par les 3 "blocs" dans le fichier:  
  
- services pour le conteneur "glpi"  
- db pour le conteneur "BDD" mariadb  
- nginx pour le conteneur "nginx"  
  
#### GLPI (backend)  
>image: diouxx/glpi:latest  
  
J'ai récupérer la dernière version de l'image glpi sur dockerhub et certifié ce qui m'assure un bon fonctionnement.  
  
> environment:  
GLPI_DB_HOST: db  
GLPI_DB_NAME: bdd_glpi  
GLPI_DB_USER: user1  
GLPI_DB_PASSWORD: donttouchmydb  
  
Toutes les données de mon glpi seront stockées sur ma BDD mariadb, je dois donc spécifier le nom de l'hôte ainsi que le nom de ma base de données, le user est le mot de passe de celle-ci.  Ces données seront identiques sur le conteneur mariadb. 

>restart: unless-stopped 

Si mon conteneur s'arrête d'une autre façon que part une exécution manuelle, il redémarrera automatiquement. (appliqué sur les 3 conteneurs)
  
Je précise également que glpi dépend de ma BDD , on vérifie que le conteneur db est démarré avant de démarrer le conteneur glpi
> depend_on:  
    - db  
  
#### NGINX (frontend)  
  
>image: nginx:latest  
  
On récupère également la dernière image à jour mais pour nginx cette fois-ci.  
  
C'est nginx qui va nous permetrre d'afficher l'interface graphique de glpi, on précise donc un port sur lequel on va l'exposer, pour ma part le **8085**.  
  
> ports:  
- "8085:80"  
  
Je précise également que nginx dépend de mon glpi, on vérifie que le conteneur glpi est démarré avant de démarrer le conteneur nginx
  
> depends_on:  
- glpi  
  
#### Base de données

>image: mariadb:latest

On récupère également la dernière image à jour de mariadb.
>environment:
      MYSQL_ROOT_PASSWORD: rootpassword
      MYSQL_DATABASE: bdd_glpi
      MYSQL_USER: user1
      MYSQL_PASSWORD: donttouchmydb

On créer la base de données et on indique les différentes infos comme les identifiants de la bdd mais aussi le mot de passe root pour accéder à mariadb en tant que root.

#### Les volumes

>volumes:
      - db_data:/var/lib/mysql
     
>volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro

Globalement, ces 2 commandes permettent de stockés les données des conteneur nginx et bdd_glpi directement sur la machine.
Cela permet de garder les données même si les conteneurs sont détruis ou supprimés.
Pour le volume, le fichier nginx.conf est configuré personnellement, on le verra par la suite

#### Réseau

Pour ce TP, le réseau doit être organisé comme tel :
[![Image](https://i.goopics.net/5jsvmk.png)](https://goopics.net/i/5jsvmk)

Cela nous montre que :

**Nginx** doit pouvoir communiquer avec GLPI mais pas avec la BDD.
La **BDD** doit uniquement communiqué avec GLPI (isolé).
**GLPI** peux communiquer avec Nginx et la BDD.

Pour se faire, j'ai configuré 2 réseaux distinct dans le docker-compose.
Un réseau **public_network** et **private_network**.

>networks:
  public_network:
    driver: bridge  #mode de réseau par défaut de Docker
  private_network:
    driver: bridge

**`public_network`** :

-   Conçu pour connecter les services qui doivent être accessibles à partir de l'extérieur (par exemple, via Internet ou réseau local).
-   GLPI et Nginx sont sur ce réseau.

**`private_network`** :

-   Conçu pour permettre une communication interne entre tes services sans qu'ils soient exposés à l'extérieur.
-   GLPI et MariaDB y sont connectés, permettant à GLPI de parler à la base de données sans exposition directe.

### Description du fichier nginx.conf

Pour faire en sorte que les requêtes entre un utilisateur et glpi passe obligatoirement par nginx, il a fallu configuré le nginx.conf . Voilà à quoi il ressemble:

```bash
worker_processes 1;

events {
    worker_connections 1024;
}

http {
    server {
        listen 80;

        server_name glpi.local;

        location / {
            proxy_pass http://glpi:80;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
    }
}
```
Ce  fichier permet de configuré nginx comme un reverse proxy, c'est à dire qu'il va redirigé toutes les requêtes HTTP sur le port 80 vers le backend à savoir glpi.


>proxy_pass http://glpi:80; 

Il redirige toutes les requêtes capturées vers le conteneur glpi sur son port 80.
>proxy_set_header Host $host; 

Il transmet le nom d'hôte original au backend.
>proxy_set_header X-Real-IP $remote_addr; 

Il transmet l'adresse IP réelle du client au backend.
>proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for; }

Il ajoute l'adresse IP du client à une liste d'adresses dans l'en-tête HTTP.

## Conclusion
Maintenant que tous les fichiers sont configuré, il suffit de le mettre dans le même répertoire puis exécuter la commande :
```bash
docker compose up -d
```
Pour lancer la création des conteneurs.

## Optionnel

Il est possible de rajouter un script (sauvegarde.sh) de sauvegarde automatique des volumes.

```bash
#!/bin/bash

# Dossier où seront stockées les sauvegardes
BACKUP_DIR="/path/to/backup/directory"
DATE=$(date +\%Y\%m\%d\%H\%M\%S)
BACKUP_NAME="docker_volume_backup_$DATE.tar.gz"

# Liste des volumes Docker à sauvegarder
VOLUMES=$(docker volume ls -q)

# Crée un fichier de sauvegarde tar.gz
docker run --rm -v $VOLUMES:/volumes -v $BACKUP_DIR:/backup busybox tar czf /backup/$BACKUP_NAME -C /volumes .

# Affiche un message de confirmation
echo "Sauvegarde effectuée avec succès. Fichier de sauvegarde : $BACKUP_DIR/$BACKUP_NAME"
```
Pour automatiser la sauvegarde, on ajoute ce script dans une tâche cron:

Dans le fichier crontab :

`0 0 * * * /path/to/sauvegarde.sh` 

Cela exécutera le script tous les jours à 00:00.

On peux également créer un script de restauration (restauration.sh):

```bash
#!/bin/bash

# Dossier où sont stockées les sauvegardes
BACKUP_DIR="/path/to/backup/directory"
BACKUP_FILE="docker_volume_backup_YYYYMMDDHHMMSS.tar.gz"

# Création d'un conteneur temporaire pour restaurer la sauvegarde
docker run --rm -v $BACKUP_DIR:/backup -v /var/lib/docker/volumes:/volumes busybox tar xzf /backup/$BACKUP_FILE -C /volumes
```
Ici, on restaure la sauvegarde en extrayant le fichier tar dans le répertoire des volumes Docker.
