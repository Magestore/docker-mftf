FROM php:7.2.13

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
		procps vim iputils-ping \
    && pecl install mcrypt-1.0.1 \
    && docker-php-ext-install -j$(nproc) xsl intl pdo_mysql soap zip opcache bcmath \
	&& docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-configure gd \
        --with-jpeg-dir=/usr/local/ \
        --with-png-dir=/usr/local/ \
        --with-freetype-dir=/usr/local/ \
        --with-gd --enable-shared \
        #--with-t1lib --enable-gd-native-ttf \
    && docker-php-ext-enable mcrypt \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install composer
RUN curl https://getcomposer.org/installer -o composer-setup.php \
    && php composer-setup.php --install-dir=/usr/local/bin/ --filename=composer \
    && php -r "unlink('composer-setup.php');"

# Fix permission denied of execute files
RUN chmod +x /usr/local/bin/docker-php-entrypoint

# Back
RUN rm -rf /var/www/.composer ; mkdir -p /var/www/.composer ; chmod -R www-data:www-data /var/www
WORKDIR /var/www/html
