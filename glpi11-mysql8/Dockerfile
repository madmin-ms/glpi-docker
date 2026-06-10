FROM ubuntu:24.04

ENV MARIADB_HOST mariadb-glpi11
ENV MARIADB_PORT 3306
ENV MARIADB_DATABASE glpi
ENV MARIADB_USER glpi-user
ENV MARIADB_PASSWORD glpi-pass
ENV TIMEZONE Europe/Budapest
ENV DEBIAN_FRONTEND noninteractive

WORKDIR /var/www/html

RUN apt -y update
RUN apt -y upgrade
RUN apt install --yes --no-install-recommends \
    apache2 \
    php \
    php-mysql \
    php-ldap \
    php-xmlrpc \
    php-imap \
    curl \
    php-curl \
    php-gd \
    php-mbstring \
    php-xml \
    php-cas \
    php-intl \
    php-zip \
    php-bz2 \
    php-yaml \
    php-bcmath \
    wget \
    ca-certificates \
    jq \
    git \
    bzip2 \
    unzip \
    default-mysql-client \
    iputils-ping \
    telnet \
    cron

RUN rm -rf /var/lib/apt/lists/*

RUN GLPI_VERSION=$(curl -s https://api.github.com/repos/glpi-project/glpi/releases | \
        jq -r '[.[] | select(.prerelease == false and .draft == false) | select(.tag_name | startswith("11."))] | first | .tag_name') && \
    echo "Installing GLPI ${GLPI_VERSION}" && \
    curl -L "https://github.com/glpi-project/glpi/releases/download/${GLPI_VERSION}/glpi-${GLPI_VERSION}.tgz" -o /tmp/glpi.tgz && \
    tar -zxf /tmp/glpi.tgz -C /tmp/ && \
    mv /tmp/glpi/* /var/www/html/ && \
    chown -R www-data:www-data /var/www/html && \
    rm -rf /tmp/glpi.tgz

RUN sed -i 's/session.cookie_httponly =/session.cookie_httponly = On/' /etc/php/8.3/apache2/php.ini
ADD assets/php.d /etc/php/8.3/apache2/conf.d
ADD assets/apache/000-default.conf /etc/apache2/sites-available/
RUN rm -rf /var/www/html/index.html
RUN a2enmod rewrite

ADD assets/htaccess install/.htaccess
RUN rm -f /var/www/html/install/install.php
ADD assets/scripts/ /opt/
RUN chmod 755 /opt/*.sh
RUN chmod +x /opt/*.sh

RUN echo "* * * * * php /var/www/html/front/cron.php" > /etc/cron.d/glpi-cron
RUN chmod 0644 /etc/cron.d/glpi-cron
RUN crontab -u www-data /etc/cron.d/glpi-cron

RUN cp -pdrf /var/www/html /glpi-mount

EXPOSE 80/tcp

CMD ["sh", "-c", "service cron start && /opt/glpi-entrypoint.sh"]
