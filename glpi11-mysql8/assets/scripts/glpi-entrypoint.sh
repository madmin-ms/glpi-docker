#!/bin/bash

MountCheck() {
  if [ ! "$(ls -A /var/www/html)" ]; then
    echo "GLPI volume empty. Populating with image default data."
    cp -pdrf /glpi-mount/* /var/www/html
    chown -R www-data:www-data /var/www/html
  fi
}

ConfigDataBase() {
  mkdir -p /var/www/html/config
  {
    echo "<?php"
    echo "class DB extends DBmysql {"
    echo "   public \$dbhost     = \"${MARIADB_HOST}\";"
    echo "   public \$dbport     = \"${MARIADB_PORT}\";"
    echo "   public \$dbuser     = \"${MARIADB_USER}\";"
    echo "   public \$dbpassword = \"${MARIADB_PASSWORD}\";"
    echo "   public \$dbdefault  = \"${MARIADB_DATABASE}\";"
    echo "}"
    echo
  } >/var/www/html/config/config_db.php
}

FreshInstallCheck() {
  echo "Waiting for Apache to respond..."
  until curl -s -o /dev/null -w "%{http_code}" localhost | grep -qE "^[1-9][0-9]{2}$"; do
    echo "Apache not ready yet."
    sleep 2
  done

  echo "Checking GLPI DB availability"
  until ! curl -s localhost | grep -q "A link to the SQL server could not be established"; do
    echo "GLPI DB isn't ready."
    sleep 2
  done
  echo "GLPI DB is up! Resuming entrypoint..."

  GLPI_RESPONSE=$(curl -s localhost)
  if echo "$GLPI_RESPONSE" | grep -q "Error accessing config table"; then
    echo "DB schema not installed. Installing"
    /usr/bin/php /var/www/html/bin/console db:install -n --force
    chown -R www-data:www-data /var/www/html/
  elif echo "$GLPI_RESPONSE" | grep -q "GLPI - Authentication"; then
    echo "DB Installed. Resuming starting process"
  fi
}

MountCheck
ConfigDataBase

chown -R www-data:www-data /var/www/html/
a2enmod rewrite && service apache2 restart && service apache2 stop
rm -rf /var/www/html/index.html
/usr/sbin/apache2ctl -D FOREGROUND &
FreshInstallCheck
wait
