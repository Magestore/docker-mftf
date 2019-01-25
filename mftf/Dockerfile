FROM php:7.2.13-apache

# php extensions to run Magento
RUN apt-get update && apt-get install -y \
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

# Install composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php -r "if (hash_file('sha384', 'composer-setup.php') === '93b54496392c062774670ac18b134c3b3a95e5a5e5c8f1a9f115f203b75bf9a129d5daa8ba6a13e2cc8a1da0806388a8') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
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

# Run apache server script
COPY mysql.php mysql.php
COPY run-apache /usr/local/bin/
RUN chmod +x /usr/local/bin/run-apache

CMD ["run-apache"]


# Prepare Magento 2.3-develop
#RUN set -ex \
#    && . "$APACHE_ENVVARS" \
#    && rm "$APACHE_LOG_DIR"/* \
#    && rm -rf /var/www/html && mkdir -p /var/www \
#    && cd /var/www && git clone https://github.com/magento/magento2.git html \
#    && cd /var/www/html && git checkout 2.3-develop \
#    && chown -R "$APACHE_RUN_USER" /var/www/html

# Prepare Magento 2.3 downloaded from magento released
COPY CE/2.3.0.tar.bz2 magento.tar.bz2
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
    && mkdir -p /var/www/.composer && chown -R $APACHE_RUN_USER /var/www/.composer \
	&& su "$APACHE_RUN_USER" -s /bin/bash -c \
        " composer require \
        authorizenet/authorizenet \
        paypal/rest-api-sdk-php:* \
        paypal/merchant-sdk-php:* \
        stripe/stripe-php:* ; "

COPY .env dev/tests/acceptance/.env
COPY rootCA.pem /usr/local/share/ca-certificates/local.crt
#RUN mv dev/tests/acceptance/.htaccess.sample dev/tests/acceptance/.htaccess && update-ca-certificates

# Functional Test
WORKDIR /var/www/html/dev/tests/functional
RUN set -ex \
    && . "$APACHE_ENVVARS" \
    && su "$APACHE_RUN_USER" -s /bin/bash -c \
    'php /var/www/html/vendor/composer/composer/bin/composer install'
# RUN mv .htaccess.sample .htaccess
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

# install some app after build image
RUN apt-get update && apt-get install -y \
        procps \
    && docker-php-ext-configure gd --with-gd --enable-shared \
        --with-jpeg-dir=/usr/include/ \
        --with-png-dir=/usr/include/ \
        --with-freetype-dir=/usr/include/freetype2/freetype \
        --with-t1lib --enable-gd-native-ttf \
    && docker-php-ext-install -j$(nproc) gd \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
