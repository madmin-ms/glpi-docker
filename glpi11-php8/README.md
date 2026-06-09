# madminhu/glpi11

Dockerizált [GLPI 11](https://glpi-project.org/) IT eszközkezelő és helpdesk rendszer. Az image mindig a legújabb stabil GLPI 11.x verziót tartalmazza.

**Stack:** Ubuntu 24.04 · Apache2 · PHP 8.3 · APCu cache  
**Platform:** `linux/arm64`

## Gyors indítás

```yaml
services:
  glpi11:
    image: madminhu/glpi11:latest
    ports:
      - "80:80"
    environment:
      MARIADB_HOST: mariadb
      MARIADB_DATABASE: glpi
      MARIADB_USER: glpi-user
      MARIADB_PASSWORD: glpi-pass
      TIMEZONE: Europe/Budapest
    volumes:
      - glpi-data:/var/www/html
    depends_on:
      - mariadb

  mariadb:
    image: mariadb:10.11
    environment:
      MYSQL_ROOT_PASSWORD: root-pass
      MYSQL_DATABASE: glpi
      MYSQL_USER: glpi-user
      MYSQL_PASSWORD: glpi-pass
    volumes:
      - mariadb-data:/var/lib/mysql

volumes:
  glpi-data:
  mariadb-data:
```

Alapértelmezett bejelentkezés: `glpi` / `glpi`

## Környezeti változók

| Változó | Alapértelmezett | Leírás |
|---------|-----------------|--------|
| `MARIADB_HOST` | `mariadb-glpi11` | MariaDB szerver hostname |
| `MARIADB_PORT` | `3306` | MariaDB port |
| `MARIADB_DATABASE` | `glpi` | Adatbázis neve |
| `MARIADB_USER` | `glpi-user` | Adatbázis felhasználó |
| `MARIADB_PASSWORD` | `glpi-pass` | Adatbázis jelszó |
| `TIMEZONE` | `Europe/Budapest` | Időzóna |

## Kötet

| Útvonal | Tartalom |
|---------|----------|
| `/var/www/html` | GLPI alkalmazás fájlok (adatok, config, feltöltések) |

## Előre telepített pluginek

| Plugin | Verzió |
|--------|--------|
| Generic Object | 2.9.1 |
| Additional Fields | 1.12.0 |
| Data Injection | 2.8.1 |
| Form Creator | 2.10.3 |
| OCS Inventory NG | 1.7.1 |
| GLPI Modifications | 2.0.2 |

## Forráskód

[github.com/madmin-ms/glpi-docker](https://github.com/madmin-ms/glpi-docker)
