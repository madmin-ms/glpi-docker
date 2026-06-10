#!/bin/bash
# GLPI 10 → GLPI 11 frissítési script (MySQL variáns)
# Használat: sudo bash upgrade-glpi10-to-glpi11-mysql.sh
# Szükséges: .env fájl a script mellett (lásd .env.example)

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()  { echo -e "${BLUE}[INFO]${NC}  $1"; }
ok()   { echo -e "${GREEN}[OK]${NC}    $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $1"; }
die()  { echo -e "${RED}[HIBA]${NC}  $1"; exit 1; }

# --- .env betöltése ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"

if [ ! -f "$ENV_FILE" ]; then
    die ".env fájl nem található! Másold: cp .env.example .env és töltsd ki."
fi
# shellcheck disable=SC1090
source "$ENV_FILE"

# Kötelező változók ellenőrzése
: "${MARIADB_HOST:?Hiányzó: MARIADB_HOST}"
: "${MARIADB_PORT:?Hiányzó: MARIADB_PORT}"
: "${MARIADB_DATABASE:?Hiányzó: MARIADB_DATABASE}"
: "${MARIADB_USER:?Hiányzó: MARIADB_USER}"
: "${MARIADB_PASSWORD:?Hiányzó: MARIADB_PASSWORD}"
: "${GLPI_CONTAINER_NAME:?Hiányzó: GLPI_CONTAINER_NAME}"
: "${GLPI_DATA_PATH:?Hiányzó: GLPI_DATA_PATH}"
: "${GLPI_BACKUP_PATH:?Hiányzó: GLPI_BACKUP_PATH}"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="${GLPI_BACKUP_PATH}/${TIMESTAMP}"

# ============================================================
# 0. FÁZIS — ELLENŐRZÉSEK
# ============================================================
echo ""
echo "======================================================"
echo "  GLPI 10 → GLPI 11 frissítés (MySQL)"
echo "  $(date)"
echo "======================================================"
echo ""

log "Ellenőrzések..."

# MySQL verzió (minimum 8.0)
log "MySQL verzió ellenőrzése..."
MYSQL_VER=$(docker exec "$MARIADB_HOST" mysql --version 2>/dev/null \
    | grep -oP '\d+\.\d+\.\d+' | head -1) \
    || die "Nem érhető el a MySQL konténer: ${MARIADB_HOST}"

MYSQL_MAJOR=$(echo "$MYSQL_VER" | cut -d. -f1)

if [ "$MYSQL_MAJOR" -lt 8 ]; then
    die "MySQL $MYSQL_VER túl régi! GLPI 11-hez minimum MySQL 8.0 szükséges."
fi
ok "MySQL $MYSQL_VER — megfelelő"

# GLPI konténer fut?
if ! docker ps --format '{{.Names}}' | grep -q "^${GLPI_CONTAINER_NAME}$"; then
    warn "A GLPI konténer (${GLPI_CONTAINER_NAME}) nem fut. Folytatás..."
fi

# Data könyvtár létezik?
[ -d "$GLPI_DATA_PATH" ] || die "GLPI adat könyvtár nem található: ${GLPI_DATA_PATH}"

# glpi.key megvan?
if [ ! -f "${GLPI_DATA_PATH}/config/glpi.key" ]; then
    warn "Nem található glpi.key — az adatbázis titkosított adatai nem lesznek visszafejthetők!"
    read -rp "Folytatod? (igen/nem): " CONFIRM
    [ "$CONFIRM" = "igen" ] || die "Megszakítva."
fi

echo ""
echo "--- Összefoglalás ---"
echo "  Konténer:      ${GLPI_CONTAINER_NAME}"
echo "  MySQL host:    ${MARIADB_HOST}:${MARIADB_PORT}"
echo "  Adatbázis:     ${MARIADB_DATABASE}"
echo "  Adat könyvtár: ${GLPI_DATA_PATH}"
echo "  Backup helye:  ${BACKUP_DIR}"
echo ""
read -rp "Elindítod a frissítést? (igen/nem): " CONFIRM
[ "$CONFIRM" = "igen" ] || die "Megszakítva."

# ============================================================
# 1. FÁZIS — BACKUP
# ============================================================
echo ""
log "=== 1. FÁZIS: Backup ==="

mkdir -p "$BACKUP_DIR"/{db,files,config}

log "Adatbázis mentése (mysqldump)..."
docker exec "$MARIADB_HOST" mysqldump \
    -u "$MARIADB_USER" \
    -p"$MARIADB_PASSWORD" \
    --single-transaction \
    --routines \
    --triggers \
    "$MARIADB_DATABASE" \
    > "${BACKUP_DIR}/db/glpi_${TIMESTAMP}.sql"
ok "DB backup: ${BACKUP_DIR}/db/glpi_${TIMESTAMP}.sql"

log "config/ mentése..."
cp -r "${GLPI_DATA_PATH}/config" "${BACKUP_DIR}/config/"
ok "config backup kész"

log "files/ mentése..."
cp -r "${GLPI_DATA_PATH}/files" "${BACKUP_DIR}/files/"
ok "files backup kész"

if [ -d "${GLPI_DATA_PATH}/plugins" ]; then
    log "plugins/ mentése..."
    cp -r "${GLPI_DATA_PATH}/plugins" "${BACKUP_DIR}/"
    ok "plugins backup kész"
fi

ok "Backup teljes: ${BACKUP_DIR}"

# ============================================================
# 2. FÁZIS — GLPI 10 LEÁLLÍTÁSA
# ============================================================
echo ""
log "=== 2. FÁZIS: GLPI 10 leállítása ==="

if docker ps --format '{{.Names}}' | grep -q "^${GLPI_CONTAINER_NAME}$"; then
    log "Konténer leállítása: ${GLPI_CONTAINER_NAME}"
    docker stop "$GLPI_CONTAINER_NAME"
    docker rm "$GLPI_CONTAINER_NAME"
    ok "Konténer leállítva és eltávolítva"
else
    warn "Konténer már nem fut, kihagyva"
fi

# ============================================================
# 3. FÁZIS — VOLUME ELŐKÉSZÍTÉSE
# ============================================================
echo ""
log "=== 3. FÁZIS: Volume nullázása ==="

warn "A ${GLPI_DATA_PATH} tartalmát törlöm (backup megvan: ${BACKUP_DIR})"
rm -rf "${GLPI_DATA_PATH:?}"/*
ok "Volume üres"

# ============================================================
# 4. FÁZIS — GLPI 11 INDÍTÁSA
# ============================================================
echo ""
log "=== 4. FÁZIS: GLPI 11 MySQL konténer indítása ==="

log "Image frissítése..."
docker pull madminhu/glpi11-mysql:latest

log "Konténer indítása..."
docker run -d \
    --name "$GLPI_CONTAINER_NAME" \
    --restart unless-stopped \
    -p "${GLPI_PORT:-82}:80" \
    -v "${GLPI_DATA_PATH}:/var/www/html" \
    -v "${GLPI_LOG_PATH}:/var/log/apache2" \
    -e TZ="${TIMEZONE:-Europe/Budapest}" \
    -e MARIADB_HOST="$MARIADB_HOST" \
    -e MARIADB_PORT="$MARIADB_PORT" \
    -e MARIADB_USER="$MARIADB_USER" \
    -e MARIADB_PASSWORD="$MARIADB_PASSWORD" \
    -e MARIADB_DATABASE="$MARIADB_DATABASE" \
    --network glpi_network \
    madminhu/glpi11-mysql:latest

log "Várakozás a GLPI 11 fájlok másolására (MountCheck)..."
sleep 8

if [ ! -f "${GLPI_DATA_PATH}/bin/console" ]; then
    die "GLPI 11 fájlok nem kerültek a volume-ba! Ellenőrizd: docker logs ${GLPI_CONTAINER_NAME}"
fi
ok "GLPI 11 fájlok a volume-ban"

# ============================================================
# 5. FÁZIS — ADATOK VISSZAÁLLÍTÁSA
# ============================================================
echo ""
log "=== 5. FÁZIS: Kritikus adatok visszaállítása ==="

log "Titkosítási kulcs visszaállítása (glpi.key)..."
if [ -f "${BACKUP_DIR}/config/config/glpi.key" ]; then
    cp "${BACKUP_DIR}/config/config/glpi.key" "${GLPI_DATA_PATH}/config/glpi.key"
    ok "glpi.key visszaállítva"
else
    warn "glpi.key nem található a backupban!"
fi

if [ -f "${BACKUP_DIR}/config/config/glpicrypt.key" ]; then
    cp "${BACKUP_DIR}/config/config/glpicrypt.key" "${GLPI_DATA_PATH}/config/glpicrypt.key"
    ok "glpicrypt.key visszaállítva"
fi

log "Feltöltött fájlok visszaállítása (files/)..."
cp -r "${BACKUP_DIR}/files/files/." "${GLPI_DATA_PATH}/files/"
ok "files/ visszaállítva"

if [ -d "${BACKUP_DIR}/plugins" ]; then
    log "Pluginok visszaállítása..."
    cp -r "${BACKUP_DIR}/plugins/." "${GLPI_DATA_PATH}/plugins/"
    ok "plugins/ visszaállítva"
fi

log "Jogosultságok beállítása..."
docker exec "$GLPI_CONTAINER_NAME" chown -R www-data:www-data /var/www/html/
ok "Jogosultságok beállítva"

# ============================================================
# 6. FÁZIS — ADATBÁZIS FRISSÍTÉSE
# ============================================================
echo ""
log "=== 6. FÁZIS: GLPI adatbázis frissítése ==="

log "Várakozás az Apache elindulására..."
sleep 5

log "db:update futtatása..."
docker exec "$GLPI_CONTAINER_NAME" php bin/console db:update --no-interaction
ok "Adatbázis frissítve"

log "Pluginok visszaengedélyezése..."
docker exec "$GLPI_CONTAINER_NAME" php bin/console plugin:resume_execution || \
    warn "plugin:resume_execution sikertelen (lehet hogy nincs plugin)"

# ============================================================
# KÉSZ
# ============================================================
echo ""
echo "======================================================"
ok "GLPI 11 (MySQL) frissítés sikeres!"
echo ""
echo "  Backup helye:  ${BACKUP_DIR}"
echo "  GLPI 11 URL:   http://$(hostname -I | awk '{print $1}'):${GLPI_PORT:-82}"
echo ""
echo "  Következő lépések:"
echo "    1. Ellenőrizd a GLPI felületet"
echo "    2. Ellenőrizd a pluginok kompatibilitását"
echo "    3. Teszteld a bejelentkezést"
echo "======================================================"
