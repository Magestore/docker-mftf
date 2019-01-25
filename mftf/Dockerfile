FROM php:7.1.25-fpm

LABEL maintainer="Tit <mrthinlt@gmail.com>"

ENV WEB_USER www-data
ENV WEB_GROUP www-data

# Nginx env
ENV NGINX_VERSION 1.15.7-1~stretch
ENV NJS_VERSION   1.15.7.0.2.6-1~stretch

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
    && docker-php-ext-install -j$(nproc) gd mcrypt xsl intl pdo_mysql soap zip opcache bcmath \
    && docker-php-ext-configure gd \
        --with-jpeg-dir=/usr/local/ \
        --with-png-dir=/usr/local/ \
        --with-freetype-dir=/usr/local/ \
        --with-t1lib --enable-gd-native-ttf \
        --with-gd --enable-shared \
    && docker-php-ext-install -j$(nproc) gd \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Nginx
RUN set -x \
	&& apt-get update \
	&& apt-get install --no-install-recommends --no-install-suggests -y gnupg1 apt-transport-https ca-certificates \
	&& \
	NGINX_GPGKEY=573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62; \
	found=''; \
	for server in \
		ha.pool.sks-keyservers.net \
		hkp://keyserver.ubuntu.com:80 \
		hkp://p80.pool.sks-keyservers.net:80 \
		pgp.mit.edu \
	; do \
		echo "Fetching GPG key $NGINX_GPGKEY from $server"; \
		apt-key adv --keyserver "$server" --keyserver-options timeout=10 --recv-keys "$NGINX_GPGKEY" && found=yes && break; \
	done; \
	test -z "$found" && echo >&2 "error: failed to fetch GPG key $NGINX_GPGKEY" && exit 1; \
	apt-get remove --purge --auto-remove -y gnupg1 && rm -rf /var/lib/apt/lists/* \
	&& dpkgArch="$(dpkg --print-architecture)" \
	&& nginxPackages=" \
		nginx=${NGINX_VERSION} \
		nginx-module-xslt=${NGINX_VERSION} \
		nginx-module-geoip=${NGINX_VERSION} \
		nginx-module-image-filter=${NGINX_VERSION} \
		nginx-module-njs=${NJS_VERSION} \
	" \
	&& case "$dpkgArch" in \
		amd64|i386) \
# arches officialy built by upstream
			echo "deb https://nginx.org/packages/mainline/debian/ stretch nginx" >> /etc/apt/sources.list.d/nginx.list \
			&& apt-get update \
			;; \
		*) \
# we're on an architecture upstream doesn't officially build for
# let's build binaries from the published source packages
			echo "deb-src https://nginx.org/packages/mainline/debian/ stretch nginx" >> /etc/apt/sources.list.d/nginx.list \
			\
# new directory for storing sources and .deb files
			&& tempDir="$(mktemp -d)" \
			&& chmod 777 "$tempDir" \
# (777 to ensure APT's "_apt" user can access it too)
			\
# save list of currently-installed packages so build dependencies can be cleanly removed later
			&& savedAptMark="$(apt-mark showmanual)" \
			\
# build .deb files from upstream's source packages (which are verified by apt-get)
			&& apt-get update \
			&& apt-get build-dep -y $nginxPackages \
			&& ( \
				cd "$tempDir" \
				&& DEB_BUILD_OPTIONS="nocheck parallel=$(nproc)" \
					apt-get source --compile $nginxPackages \
			) \
# we don't remove APT lists here because they get re-downloaded and removed later
			\
# reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
# (which is done after we install the built packages so we don't have to redownload any overlapping dependencies)
			&& apt-mark showmanual | xargs apt-mark auto > /dev/null \
			&& { [ -z "$savedAptMark" ] || apt-mark manual $savedAptMark; } \
			\
# create a temporary local APT repo to install from (so that dependency resolution can be handled by APT, as it should be)
			&& ls -lAFh "$tempDir" \
			&& ( cd "$tempDir" && dpkg-scanpackages . > Packages ) \
			&& grep '^Package: ' "$tempDir/Packages" \
			&& echo "deb [ trusted=yes ] file://$tempDir ./" > /etc/apt/sources.list.d/temp.list \
# work around the following APT issue by using "Acquire::GzipIndexes=false" (overriding "/etc/apt/apt.conf.d/docker-gzip-indexes")
#   Could not open file /var/lib/apt/lists/partial/_tmp_tmp.ODWljpQfkE_._Packages - open (13: Permission denied)
#   ...
#   E: Failed to fetch store:/var/lib/apt/lists/partial/_tmp_tmp.ODWljpQfkE_._Packages  Could not open file /var/lib/apt/lists/partial/_tmp_tmp.ODWljpQfkE_._Packages - open (13: Permission denied)
			&& apt-get -o Acquire::GzipIndexes=false update \
			;; \
	esac \
	\
	&& apt-get install --no-install-recommends --no-install-suggests -y \
						$nginxPackages \
						gettext-base \
	&& rm -rf /var/lib/apt/lists/* /etc/apt/sources.list.d/nginx.list \
	\
# if we have leftovers from building, let's purge them (including extra, unnecessary build deps)
	&& if [ -n "$tempDir" ]; then \
		apt-get purge -y --auto-remove \
		&& rm -rf "$tempDir" /etc/apt/sources.list.d/temp.list; \
	fi

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log

# Copy nginx config
COPY nginx.conf /etc/nginx/nginx.conf

# END Install Nginx


# Install composer
RUN curl https://getcomposer.org/installer -o composer-setup.php \
    && php composer-setup.php --install-dir=/usr/local/bin/ --filename=composer \
    && php -r "unlink('composer-setup.php');"

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

# Fix permission denied of execute files
RUN chmod +x /usr/local/bin/docker-php-entrypoint

# Expose ports
EXPOSE 80 443

# Run apache server script
COPY mysql.php mysql.php
COPY run-nginx /usr/local/bin/
RUN chmod +x /usr/local/bin/run-nginx


WORKDIR /var/www/html

# Prepare Magento 2.3 downloaded from magento released
COPY CE/2.3.0.tar.bz2 magento.tar.bz2
RUN set -ex \
    && mkdir -p /var/www/html && chown -R "$WEB_USER" /var/www/html \
    && su "$WEB_USER" -s /bin/bash -c 'tar jxf magento.tar.bz2' \
    && rm magento.tar.bz2

# Prepare acceptance test
RUN set -ex \
    && su "$WEB_USER" -s /bin/bash -c \
    "echo '{ \
        \"http-basic\": { \
            \"repo.magento.com\": { \
                \"username\": \"a3380186b4ffb670466a01331a3fb375\", \
                \"password\": \"cfe4874a50552827da901971d249322a\" \
            } \
        } \
    }' > auth.json" \
    && echo "PHP-FPM run user $WEB_USER" \
    && mkdir -p /var/www/.composer && chown -R $WEB_USER /var/www/.composer \
	&& su "$WEB_USER" -s /bin/bash -c \
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
    && su "$WEB_USER" -s /bin/bash -c \
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

STOPSIGNAL SIGTERM

CMD ["run-nginx"]
