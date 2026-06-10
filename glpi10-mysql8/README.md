# madminhu/glpi10-mysql

Dockerizált [GLPI 10.0.16](https://glpi-project.org/) IT eszközkezelő rendszer, MySQL 8.0 adatbázishoz optimalizálva.

**Stack:** Ubuntu 24.04 · Apache2 · PHP 8.3 · APCu cache · MySQL client  
**Platform:** `linux/arm64`

## Gyors indítás

```yaml
services:
  glpi10:
    image: madminhu/glpi10-mysql:latest
    ports:
      - "80:80"
    environment:
      MARIADB_HOST: mysql
      MARIADB_DATABASE: glpi
      MARIADB_USER: glpi-user
      MARIADB_PASSWORD: glpi-pass
      TIMEZONE: Europe/Budapest
    volumes:
      - glpi-data:/var/www/html
    depends_on:
      - mysql

  mysql:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: root-pass
      MYSQL_DATABASE: glpi
      MYSQL_USER: glpi-user
      MYSQL_PASSWORD: glpi-pass
    volumes:
      - mysql-data:/var/lib/mysql

volumes:
  glpi-data:
  mysql-data:
```

Alapértelmezett bejelentkezés: `glpi` / `glpi`

## Különbség a MariaDB variánstól

Ez az image `default-mysql-client` csomaggal készült, MySQL 8.0+ szerverekhez ajánlott.

## Forráskód

[github.com/madmin-ms/glpi-docker](https://github.com/madmin-ms/glpi-docker)
