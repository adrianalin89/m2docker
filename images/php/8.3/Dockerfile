FROM php:8.3-fpm-bookworm

ARG USER_ID
ARG GROUP_ID

RUN groupadd -g "$GROUP_ID" app \
  && useradd -g "$GROUP_ID" -u "$USER_ID" -d /var/www -s /bin/bash app

RUN mkdir -p /etc/nginx/html /var/www/html /sock \
  && chown -R app:app /etc/nginx /var/www /usr/local/etc/php/conf.d /sock

RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash -

RUN apt-get update && apt-get install -y \
    cron \
    default-mysql-client \
    git \
    gnupg \
    gzip \
    libbz2-dev \
    libfreetype6-dev \
    libicu-dev \
    libjpeg62-turbo-dev \
    libmagickwand-dev \
    libmcrypt-dev \
    libonig-dev \
    libpng-dev \
    libsodium-dev \
    libssh2-1-dev \
    libwebp-dev \
    libxslt1-dev \
    libzip-dev \
    lsof \
    mailutils \
    msmtp \
    nodejs \
    procps \
    strace \
    vim \
    zip \
    zlib1g-dev \
    nano \
  && rm -rf /var/lib/apt/lists/*

RUN pecl channel-update pecl.php.net && pecl install \
    redis-6.0.2 \
    ssh2-1.3.1 \
    swoole-5.1.1 \
    xdebug-3.3.2 \
  && pecl clear-cache \
  && rm -rf /tmp/pear

RUN curl -L https://github.com/Imagick/imagick/archive/28f27044e435a2b203e32675e942eb8de620ee58.zip -o imagick.zip \
    && unzip imagick.zip \
    && rm imagick.zip \
    && cd imagick-28f27044e435a2b203e32675e942eb8de620ee58 \
    && phpize \
    && ./configure --with-php-config=/usr/local/bin/php-config \
    && make \
    && make install \
    && echo "extension=imagick.so" >> $PHP_INI_DIR/conf.d/imagick.ini \
    && cd .. \
    && rm -rf imagick-28f27044e435a2b203e32675e942eb8de620ee58

RUN docker-php-ext-configure \
    gd --with-freetype --with-jpeg --with-webp \
  && docker-php-ext-install \
    bcmath \
    bz2 \
    calendar \
    exif \
    ftp \
    gd \
    gettext \
    intl \
    mbstring \
    mysqli \
    opcache \
    pcntl \
    pdo_mysql \
    soap \
    sockets \
    sodium \
    sysvmsg \
    sysvsem \
    sysvshm \
    xsl \
    zip \
  && docker-php-ext-enable \
    imagick \
    redis \
    ssh2 \
    xdebug


RUN git clone --branch v0.4.15 --depth=1 https://github.com/NoiseByNorthwest/php-spx.git /usr/lib/php-spx \
    && cd /usr/lib/php-spx \
    && phpize \
    && ./configure \
    && make \
    && make install

RUN curl -sS https://getcomposer.org/installer | \
  php -- --version=2.6.6 --install-dir=/usr/local/bin --filename=composer

COPY conf/spx.ini $PHP_INI_DIR/conf.d/spx.ini
COPY conf/msmtprc /etc/msmtprc
COPY conf/php.ini $PHP_INI_DIR
COPY conf/php-fpm.conf /usr/local/etc/
COPY conf/www.conf /usr/local/etc/php-fpm.d/

USER app:app
VOLUME /var/www
WORKDIR /var/www/html