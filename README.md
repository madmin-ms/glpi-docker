# glpi-docker

Dockerizált [GLPI](https://glpi-project.org/) IT eszközkezelő rendszer, Ubuntu 24.04 alapon, Apache2 + PHP 8.3 stackkel.

| Verzió | Könyvtár | Port |
|--------|----------|------|
| GLPI 10.0.16 | `glpi10-php8/` | 80 |
| GLPI 11 (legújabb stable) | `glpi11-php8/` | 8080 |

## Követelmények

- Docker
- Docker Compose

## Gyors indítás

Mindkét verzió egyszerre:

```bash
docker compose up -d
```

Csak egy verzió:

```bash
docker compose up -d glpi10 mariadb-glpi10
docker compose up -d glpi11 mariadb-glpi11
```

| Felület | URL |
|---------|-----|
| GLPI 10 | [http://localhost](http://localhost) |
| GLPI 11 | [http://localhost:8080](http://localhost:8080) |

Alapértelmezett bejelentkezési adatok: `glpi` / `glpi`

## Környezeti változók

| Változó | Alapértelmezett | Leírás |
|---------|-----------------|--------|
| `MARIADB_HOST` | `mariadb-glpi10` / `mariadb-glpi11` | MariaDB szerver hostname |
| `MARIADB_PORT` | `3306` | MariaDB port |
| `MARIADB_DATABASE` | `glpi` | Adatbázis neve |
| `MARIADB_USER` | `glpi-user` | Adatbázis felhasználó |
| `MARIADB_PASSWORD` | `glpi-pass` | Adatbázis jelszó |
| `TIMEZONE` | `Europe/Budapest` | Időzóna |

## Telepített pluginek

| Plugin | Verzió |
|--------|--------|
| [Generic Object](https://github.com/pluginsGLPI/genericobject) | 2.9.1 |
| [Fields](https://github.com/pluginsGLPI/fields) | 1.12.0 |
| [Data Injection](https://github.com/pluginsGLPI/datainjection) | 2.8.1 |
| [Form Creator](https://github.com/pluginsGLPI/formcreator) | 2.10.3 |
| [OCS Inventory NG](https://github.com/pluginsGLPI/ocsinventoryng) | 1.7.1 |
| [GLPI Modifications](https://github.com/stdonato/glpi-modifications) | 2.0.2 |

> **Megjegyzés:** A plugin verziók GLPI 10-hez teszteltek. GLPI 11 esetén ellenőrizd a kompatibilitást a `glpi11-php8/assets/scripts/glpi-plugins.sh` fájlban.

## Kötethasználat

| Kötet | Tartalom |
|-------|----------|
| `glpi10-data` | GLPI 10 fájlrendszer |
| `mariadb10-data` | GLPI 10 MariaDB adatok |
| `glpi11-data` | GLPI 11 fájlrendszer |
| `mariadb11-data` | GLPI 11 MariaDB adatok |

## Plugin telepítés

```bash
# GLPI 10
docker exec -it glpi10 bash /opt/glpi-plugins.sh

# GLPI 11
docker exec -it glpi11 bash /opt/glpi-plugins.sh
```

## Adatbázis újratelepítés

```bash
# GLPI 10
docker exec -it glpi10 bash /opt/glpi-fresh-install.sh

# GLPI 11
docker exec -it glpi11 bash /opt/glpi-fresh-install.sh
```
