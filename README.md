# glpi-docker

Dockerizált [GLPI 10.0.16](https://glpi-project.org/) IT eszközkezelő rendszer, Ubuntu 24.04 alapon, Apache2 + PHP 8.3 stackkel.

## Követelmények

- Docker
- Docker Compose

## Gyors indítás

```bash
docker compose up -d
```

A GLPI felület elérhető: [http://localhost](http://localhost)

Alapértelmezett bejelentkezési adatok: `glpi` / `glpi`

## Környezeti változók

| Változó | Alapértelmezett | Leírás |
|---------|-----------------|--------|
| `MARIADB_HOST` | `mariadb-glpi` | MariaDB szerver hostname |
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

## Kötethasználat

| Kötet | Tartalom |
|-------|----------|
| `glpi-data` | GLPI fájlrendszer (`/var/www/html`) |
| `mariadb-data` | MariaDB adatok (`/var/lib/mysql`) |

## Plugin telepítés

A pluginek manuálisan telepíthetők a konténer belsejéből:

```bash
docker exec -it glpi bash /opt/glpi-plugins.sh
```

## Adatbázis újratelepítés

```bash
docker exec -it glpi bash /opt/glpi-fresh-install.sh
```
