# GLPI 10 → GLPI 11 frissítési útmutató

> **Figyelem:** Frissítés előtt mindig készíts teljes backupot!

## Rendszerkövetelmények

| Komponens | GLPI 11 minimum | Ellenőrzés |
|-----------|----------------|------------|
| PHP | 8.2+ | `docker exec <glpi> php -v` |
| MariaDB | **10.6+** | `docker exec <mariadb> mariadb --version` |

## Előkészítés

### 1. `.env` fájl létrehozása

```bash
cp .env.example .env
```

Töltsd ki a `.env` fájlt a szerver adataival (soha ne commitold!):

```bash
# Kötelező értékek:
MARIADB_HOST=           # MariaDB konténer neve
MARIADB_DATABASE=       # Adatbázis neve
MARIADB_USER=           # Adatbázis felhasználó
MARIADB_PASSWORD=       # Adatbázis jelszó (csak helyi .env-ben!)
GLPI_CONTAINER_NAME=    # GLPI konténer neve
GLPI_DATA_PATH=         # GLPI adatkönyvtár útvonala
GLPI_BACKUP_PATH=       # Backup mentési hely
```

### 2. Docker Hub image elérhetőség

Győződj meg róla, hogy az új image elérhető:

```bash
docker pull madminhu/glpi11:latest
```

## Automatikus frissítés (ajánlott)

```bash
sudo bash upgrade-glpi10-to-glpi11.sh
```

A script elvégzi az összes lépést, ellenőrzésekkel és megerősítésekkel.

## Kézi frissítés (lépésről lépésre)

### 0. Ellenőrzések

```bash
# MariaDB verzió (minimum 10.6 szükséges!)
docker exec $MARIADB_HOST mariadb --version

# Szükséges könyvtárak
ls $GLPI_DATA_PATH/config/glpi.key
```

### 1. Backup

```bash
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR=$GLPI_BACKUP_PATH/$TIMESTAMP
mkdir -p $BACKUP_DIR/{db,config,files}

# Adatbázis
docker exec $MARIADB_HOST mysqldump \
    -u $MARIADB_USER -p$MARIADB_PASSWORD $MARIADB_DATABASE \
    > $BACKUP_DIR/db/glpi_$TIMESTAMP.sql

# Fájlok
cp -r $GLPI_DATA_PATH/config $BACKUP_DIR/config/
cp -r $GLPI_DATA_PATH/files  $BACKUP_DIR/files/
```

### 2. GLPI 10 leállítása

```bash
docker stop $GLPI_CONTAINER_NAME
docker rm   $GLPI_CONTAINER_NAME
```

### 3. Volume nullázása

```bash
rm -rf ${GLPI_DATA_PATH:?}/*
```

### 4. GLPI 11 indítása

```bash
docker pull madminhu/glpi11:latest

docker run -d \
    --name $GLPI_CONTAINER_NAME \
    --restart unless-stopped \
    -p ${GLPI_PORT}:80 \
    -v ${GLPI_DATA_PATH}:/var/www/html \
    -v ${GLPI_LOG_PATH}:/var/log/apache2 \
    -e TZ=$TIMEZONE \
    -e MARIADB_HOST=$MARIADB_HOST \
    -e MARIADB_PORT=$MARIADB_PORT \
    -e MARIADB_USER=$MARIADB_USER \
    -e MARIADB_PASSWORD=$MARIADB_PASSWORD \
    -e MARIADB_DATABASE=$MARIADB_DATABASE \
    --network glpi_network \
    madminhu/glpi11:latest

# Várakozás a fájlmásolásra
sleep 8
```

### 5. Adatok visszaállítása

```bash
# Titkosítási kulcs (KRITIKUS — nélküle az adatbázis titkosított adatai elvesznek!)
cp $BACKUP_DIR/config/config/glpi.key $GLPI_DATA_PATH/config/glpi.key

# Feltöltött fájlok
cp -r $BACKUP_DIR/files/files/. $GLPI_DATA_PATH/files/

# Jogosultságok
docker exec $GLPI_CONTAINER_NAME chown -R www-data:www-data /var/www/html/
```

### 6. Adatbázis frissítése

```bash
docker exec $GLPI_CONTAINER_NAME php bin/console db:update --no-interaction
docker exec $GLPI_CONTAINER_NAME php bin/console plugin:resume_execution
```

## Visszaállítás (rollback)

Ha a frissítés sikertelen:

```bash
# Konténer eltávolítása
docker stop $GLPI_CONTAINER_NAME && docker rm $GLPI_CONTAINER_NAME

# Volume visszaállítása a backupból
rm -rf ${GLPI_DATA_PATH:?}/*
cp -r $BACKUP_DIR/config/. $GLPI_DATA_PATH/config/
cp -r $BACKUP_DIR/files/.  $GLPI_DATA_PATH/files/

# Adatbázis visszaállítása
docker exec -i $MARIADB_HOST mysql \
    -u $MARIADB_USER -p$MARIADB_PASSWORD $MARIADB_DATABASE \
    < $BACKUP_DIR/db/glpi_*.sql

# GLPI 10 újraindítása
docker run -d \
    --name $GLPI_CONTAINER_NAME \
    --restart unless-stopped \
    -p ${GLPI_PORT}:80 \
    -v ${GLPI_DATA_PATH}:/var/www/html \
    -v ${GLPI_LOG_PATH}:/var/log/apache2 \
    -e MARIADB_HOST=$MARIADB_HOST \
    -e MARIADB_PORT=$MARIADB_PORT \
    -e MARIADB_USER=$MARIADB_USER \
    -e MARIADB_PASSWORD=$MARIADB_PASSWORD \
    -e MARIADB_DATABASE=$MARIADB_DATABASE \
    madminhu/glpi:10-php8
```

## Plugin kompatibilitás GLPI 11-ben

| Plugin | GLPI 11 kompatibilis? |
|--------|-----------------------|
| Generic Object | Ellenőrizd a [plugin oldalán](https://github.com/pluginsGLPI/genericobject/releases) |
| Fields | Ellenőrizd a [plugin oldalán](https://github.com/pluginsGLPI/fields/releases) |
| Data Injection | Ellenőrizd a [plugin oldalán](https://github.com/pluginsGLPI/datainjection/releases) |
| Form Creator | Ellenőrizd a [plugin oldalán](https://github.com/pluginsGLPI/formcreator/releases) |
| OCS Inventory NG | Ellenőrizd a [plugin oldalán](https://github.com/pluginsGLPI/ocsinventoryng/releases) |

> A `plugin:resume_execution` parancs futtatása után az inkompatibilis pluginek automatikusan letiltódnak. A GLPI admin felületen ellenőrizd és frissítsd őket.
