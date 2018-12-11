FROM php:7.2.13-apache

# php extensions to run Magento
RUN apt-get update && apt-get install -y \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng-dev \
        libxslt1-dev \
        libicu-dev \
        zlib1g-dev \
        curl \
        git \
    && pecl install mcrypt-1.0.1 \
    && docker-php-ext-install -j$(nproc) xsl intl pdo_mysql soap zip opcache bcmath \
    && docker-php-ext-configure gd --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-enable mcrypt \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Enable apache modes
RUN a2enmod rewrite
RUN a2enmod headers
RUN a2enmod ssl

# Mailhog
RUN curl -Lsf 'https://storage.googleapis.com/golang/go1.8.3.linux-amd64.tar.gz' | tar -C '/usr/local' -xvzf -
ENV PATH /usr/local/go/bin:$PATH
RUN go get github.com/mailhog/mhsendmail
RUN cp /root/go/bin/mhsendmail /usr/bin/mhsendmail
RUN echo 'sendmail_path = /usr/bin/mhsendmail --smtp-addr mailhog:1025' > /usr/local/etc/php/php.ini
RUN echo 'memory_limit = -1' >> /usr/local/etc/php/php.ini

# SSL
COPY server.crt /etc/ssl/certs/ssl-cert-snakeoil.pem
COPY server.key /etc/ssl/private/ssl-cert-snakeoil.key
RUN a2ensite default-ssl.conf

# Fix permission denied of execute files
RUN chmod +x /usr/local/bin/docker-php-entrypoint

# Expose ports
EXPOSE 80 443

# Run apache server script
COPY mysql.php mysql.php
COPY run-apache /usr/local/bin/
RUN chmod +x /usr/local/bin/run-apache

CMD ["run-apache"]

# Magento
COPY CE/2.3.0.tar.bz2 magento.tar.bz2
RUN set -ex \
    && . "$APACHE_ENVVARS" \
    && rm "$APACHE_LOG_DIR"/* \
    && su "$APACHE_RUN_USER" -s /bin/bash -c 'tar jxf magento.tar.bz2' \
    && rm magento.tar.bz2

# Test ENV
WORKDIR dev/tests/acceptance
RUN rm composer.lock \
    && sed -i 's/git@github.com:/https:\/\/github.com\//g' composer.json
RUN set -ex \
    && . "$APACHE_ENVVARS" \
    && chown $APACHE_RUN_USER /var/www \
    && su "$APACHE_RUN_USER" -s /bin/bash -c \
    'php /var/www/html/vendor/composer/composer/bin/composer install' \
    && su "$APACHE_RUN_USER" -s /bin/bash -c 'vendor/bin/robo build:project'
COPY .env .env
COPY rootCA.pem /usr/local/share/ca-certificates/local.crt
RUN mv .htaccess.sample .htaccess && update-ca-certificates

# Functional Test
WORKDIR /var/www/html/dev/tests/functional
RUN set -ex \
    && . "$APACHE_ENVVARS" \
    && su "$APACHE_RUN_USER" -s /bin/bash -c \
    'php /var/www/html/vendor/composer/composer/bin/composer install'
RUN mv .htaccess.sample .htaccess
COPY phpunit.xml phpunit.xml
COPY config.xml etc/config.xml

# API Functional
COPY phpunit.api.xml ../api-functional/phpunit.xml
COPY install-config-mysql.php ../api-functional/config/install-config-mysql.php

# Integration
COPY install-config-mysql.integration.php ../integration/etc/install-config-mysql.php
COPY phpunit.integration.xml ../integration/phpunit.xml

# Back
RUN rm -rf /var/www/.composer
WORKDIR /var/www/html
