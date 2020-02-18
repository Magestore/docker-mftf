FROM php:7.2-apache

# php extensions to run Magento
RUN apt-get update && apt-get install -y \
        apt-transport-https \
        libjpeg62-turbo-dev \
        libfreetype6-dev \
        libmcrypt-dev \
        libpng-dev \
        libxslt1-dev \
        libicu-dev \
        zlib1g-dev \
        curl \
        git \
        unzip \
        nano \
    && pecl install mcrypt-1.0.1 \
    && docker-php-ext-install -j$(nproc) xsl intl pdo_mysql soap zip opcache bcmath \
    && docker-php-ext-configure gd --with-gd --enable-shared \
        --with-jpeg-dir=/usr/include/ \
        --with-png-dir=/usr/include/ \
        --with-freetype-dir=/usr/include/freetype2/freetype \
        --with-t1lib --enable-gd-native-ttf \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-enable mcrypt \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN curl https://packages.sury.org/php/apt.gpg -o /etc/apt/trusted.gpg.d/php.gpg \
    && echo "deb https://packages.sury.org/php/ stretch main" > /etc/apt/sources.list.d/php.list \
    && apt-get update && apt-get install -y libsodium-dev \
    && docker-php-ext-install sodium \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install composer
RUN curl https://getcomposer.org/installer -o composer-setup.php \
    && php composer-setup.php --install-dir=/usr/local/bin/ --filename=composer \
    && php -r "unlink('composer-setup.php');"

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

# Prepare Magento 2.3-develop
#RUN set -ex \
#    && . "$APACHE_ENVVARS" \
#    && rm "$APACHE_LOG_DIR"/* \
#    && rm -rf /var/www/html && mkdir -p /var/www \
#    && cd /var/www && git clone https://github.com/magento/magento2.git html \
#    && cd /var/www/html && git checkout 2.3-develop \
#    && chown -R "$APACHE_RUN_USER" /var/www/html

# Prepare Magento 2.3 downloaded from magento released
COPY CE/2.3.3.tar.bz2 magento.tar.bz2
RUN set -ex \
    && . "$APACHE_ENVVARS" \
    && rm "$APACHE_LOG_DIR"/* \
    && su "$APACHE_RUN_USER" -s /bin/bash -c 'tar jxf magento.tar.bz2' \
    && rm magento.tar.bz2

# Prepare acceptance test
WORKDIR /var/www/html
RUN set -ex \
    && . "$APACHE_ENVVARS" \
    && su "$APACHE_RUN_USER" -s /bin/bash -c \
    "echo '{ \
        \"http-basic\": { \
            \"repo.magento.com\": { \
                \"username\": \"a3380186b4ffb670466a01331a3fb375\", \
                \"password\": \"cfe4874a50552827da901971d249322a\" \
            } \
        } \
    }' > auth.json" \
    && echo "Apache run user $APACHE_RUN_USER" \
    && su "$APACHE_RUN_USER" -s /bin/bash -c \
        " composer install " \
    && su "$APACHE_RUN_USER" -s /bin/bash -c \
        " rm vendor/bin/mftf vendor/bin/codecept vendor/bin/robo; \
        ln -s ../magento/magento2-functional-testing-framework/bin/mftf vendor/bin/mftf; \
        ln -s ../codeception/codeception/codecept vendor/bin/codecept; \
        ln -s ../consolidation/robo/robo vendor/bin/robo; \
        chmod -R +x \
            vendor/magento/magento2-functional-testing-framework/bin \
            vendor/codeception/codeception/codecept \
            vendor/consolidation/robo/robo;" \
    && su "$APACHE_RUN_USER" -s /bin/bash -c \
        " chmod -R +x vendor/bin && vendor/bin/mftf build:project"

COPY .env dev/tests/acceptance/.env
COPY rootCA.pem /usr/local/share/ca-certificates/local.crt
RUN mv dev/tests/acceptance/.htaccess.sample dev/tests/acceptance/.htaccess && update-ca-certificates

# # Functional Test
# WORKDIR /var/www/html/dev/tests/functional
# RUN set -ex \
#     && . "$APACHE_ENVVARS" \
#     && su "$APACHE_RUN_USER" -s /bin/bash -c \
#     'php /var/www/html/vendor/composer/composer/bin/composer install'
# RUN mv .htaccess.sample .htaccess
# COPY phpunit.xml phpunit.xml
# COPY config.xml etc/config.xml

# API Functional
COPY phpunit.api.xml ../api-functional/phpunit.xml
COPY install-config-mysql.php ../api-functional/config/install-config-mysql.php

# Integration
COPY install-config-mysql.integration.php ../integration/etc/install-config-mysql.php
COPY phpunit.integration.xml ../integration/phpunit.xml

# Back
RUN rm -rf /var/www/.composer
WORKDIR /var/www/html

# Run apache server script
COPY mysql.php mysql.php
COPY run-apache /usr/local/bin/
RUN chmod +x /usr/local/bin/run-apache

CMD ["run-apache"]
