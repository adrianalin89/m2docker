ARG FRANKENPHP_VERSION=1.13.2
FROM dunglas/frankenphp:${FRANKENPHP_VERSION}-php8.5-bookworm

USER root

ARG USER_ID
ARG GROUP_ID
# Tool versions, pinned in the repository
ARG NODE_VERSION=24
ARG COMPOSER_VERSION=2.10.3

RUN userdel -f www-data
RUN if getent group www-data ; then groupdel www-data; fi
RUN if ! getent group ${GROUP_ID} ; then groupadd -g ${GROUP_ID} www-data ; else groupmod -n www-data $(getent group ${GROUP_ID} | cut -d: -f1); fi
RUN useradd -l -u ${USER_ID} -g www-data www-data
RUN mkdir -p /var/www && chown -R www-data:www-data /var/www

RUN install -d -m 0755 -o www-data -g www-data /home/www-data
RUN chown -R www-data:www-data /home/www-data

# Caddy keeps its runtime state here, it must be writable by the non-root user
RUN mkdir -p /data/caddy /config/caddy && chown -R www-data:www-data /data /config

RUN mkdir /var/log/supervisor
RUN chown -R www-data:www-data /var/log/supervisor
RUN touch /var/run/supervisord.pid
RUN touch /var/run/crond.pid
RUN chown -R www-data:www-data /var/run
RUN chown www-data:www-data /var/run/supervisord.pid /var/run/crond.pid

RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash -

RUN apt-get update && apt-get install -y \
    cron \
    default-mysql-client \
    git \
    gnupg \
    gzip \
    lsof \
    mailutils \
    msmtp \
    nodejs \
    procps \
    strace \
    unzip \
    vim \
    zip \
    nano \
    logrotate \
    supervisor \
  && rm -rf /var/lib/apt/lists/*

# install-php-extensions ships with the FrankenPHP image and pulls the system
# libraries each extension needs. PHP 8.5 has OPcache built in.
# swoole is left out on purpose: Magento doesn't use it and it conflicts with
# FrankenPHP's own threaded (ZTS) server.
RUN install-php-extensions \
    bcmath \
    bz2 \
    calendar \
    exif \
    ftp \
    gd \
    gettext \
    intl \
    mysqli \
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
    redis-6.3.0 \
    ssh2-1.5.0 \
    imagick-3.8.1 \
    xdebug-3.5.1

# ImageMagick's OpenMP threads conflict with FrankenPHP's threads (known issue),
# keep it single threaded.
ENV MAGICK_THREAD_LIMIT=1

RUN curl -sS https://getcomposer.org/installer | \
  php -- --version=${COMPOSER_VERSION} --install-dir=/usr/local/bin --filename=composer

COPY conf/Caddyfile /etc/caddy/Caddyfile
COPY conf/msmtprc /etc/msmtprc
COPY conf/logrotate-magento /etc/logrotate.d/magento
COPY conf/ecomscan-daily.sh /usr/local/bin/ecomscan-daily.sh
RUN chmod +x /usr/local/bin/ecomscan-daily.sh
ADD conf/crontab /etc/cron.d/cron
RUN crontab -u www-data /etc/cron.d/cron

RUN usermod -a -G crontab www-data
RUN chmod gu+s /usr/sbin/cron

USER www-data
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

WORKDIR /var/www/src
