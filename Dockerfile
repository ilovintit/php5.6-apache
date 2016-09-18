FROM php:5.6-apache
MAINTAINER lionetech <lion@lionetech.com>

RUN apt-get update && apt-get install -y \
    bzip2 \
    libcurl4-openssl-dev \
    libfreetype6-dev \
    libicu-dev \
    libjpeg-dev \
    libmcrypt-dev \
    libmemcached-dev \
    libpng12-dev \
    libpq-dev \
    libxml2-dev \
    libfreetype6-dev \
    git \
    curl \
    rsyslog \
    cron \
    supervisor \
    cron \
    unzip \
    --no-install-recommends \
    && rm -r /var/lib/apt/lists/*

RUN docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr --with-freetype-dir=/usr\
	&& docker-php-ext-install gd intl mbstring mcrypt mysql opcache pdo_mysql pdo_pgsql pgsql zip curl
RUN { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=60'; \
		echo 'opcache.fast_shutdown=1'; \
		echo 'opcache.enable_cli=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini

RUN pecl install APCu-4.0.10 memcached mongodb memcache\
	&& docker-php-ext-enable apcu memcached memcache mongodb

RUN mkdir -p /var/lock/apache2 /var/run/apache2 /var/log/supervisor

#调整时区

RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
RUN echo "date.timezone = Asia/Shanghai" >> /etc/php.ini

#安装composer

RUN curl -sS https://getcomposer.org/installer -o composer-setup.php
RUN php composer-setup.php --install-dir=/bin --filename=composer

#配置apache

RUN a2enmod ssl rewrite
RUN { \
    echo '<VirtualHost *:80>';\
    	echo 'ServerAdmin webmaster@localhost';\
    	echo 'DocumentRoot /var/www/html';\
    	echo 'ErrorLog ${APACHE_LOG_DIR}/error.log';\
    	echo 'CustomLog ${APACHE_LOG_DIR}/access.log combined';\
    	echo 'SetEnv HTTPS ${FORCE_HTTPS}';\
    echo '</VirtualHost>';\
} > /etc/apache2/sites-available/000-default.conf
ENV HTTPS off
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf
RUN echo "export FORCE_HTTPS=\${HTTPS}" >> /etc/apache2/envvars
