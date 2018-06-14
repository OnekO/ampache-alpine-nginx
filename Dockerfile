FROM alpine

RUN apk --no-cache add \
    coreutils \
    supervisor \
    nginx \
    php7 \
    php7-fpm \
    php7-mcrypt \
    php7-iconv \
    php7-zip \
    php7-gd \
    php7-exif \
    php7-imagick \
    php7-apcu \
    php7-phar \
    php7-json \
    php7-curl \
    php7-ctype \
    php7-fileinfo \
    php7-xmlwriter \
    php7-mbstring \
    php7-mysqli \
    php7-opcache \
    php7-tokenizer \
    php7-pdo php7-pdo_mysql \
    php7-simplexml \
    php7-session \
    tzdata \
    git

RUN set -x ; \
    addgroup -g 82 -S www-data ; \
    adduser -u 82 -D -S -G www-data www-data && exit 0 ; exit 1

ENV VIRTUAL_HOST="ampache.lan" \
    NGINX_ROOT="/var/www/ampache"

COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/ampache.conf /etc/nginx/conf.d/default.conf

RUN sed -i "s|server_name my_server_name;|server_name ${VIRTUAL_HOST};|g" /etc/nginx/conf.d/default.conf && \
    sed -i "s|root /path/to/ampache/root/directory;|root ${NGINX_ROOT};|g" /etc/nginx/conf.d/default.conf

ENV PHP_FPM_USER="www-data" \
    PHP_FPM_GROUP="www-data" \
    PHP_FPM_LISTEN_MODE="0660" \
    PHP_MEMORY_LIMIT="512M" \
    PHP_MAX_UPLOAD="100M" \
    PHP_MAX_FILE_UPLOAD="200" \
    PHP_MAX_POST="100M" \
    PHP_DISPLAY_ERRORS="On" \
    PHP_DISPLAY_STARTUP_ERRORS="On" \
    PHP_ERROR_REPORTING="E_COMPILE_ERROR\|E_RECOVERABLE_ERROR\|E_ERROR\|E_CORE_ERROR" \
    PHP_CGI_FIX_PATHINFO=0

RUN sed -i "s|;listen.owner\s*=\s*nobody|listen.owner = ${PHP_FPM_USER}|g" /etc/php7/php-fpm.conf && \
    sed -i "s|;listen.group\s*=\s*nobody|listen.group = ${PHP_FPM_GROUP}|g" /etc/php7/php-fpm.conf && \
    sed -i "s|;listen.mode\s*=\s*0660|listen.mode = ${PHP_FPM_LISTEN_MODE}|g" /etc/php7/php-fpm.conf && \
    sed -i "s|user\s*=\s*nobody|user = ${PHP_FPM_USER}|g" /etc/php7/php-fpm.conf && \
    sed -i "s|group\s*=\s*nobody|group = ${PHP_FPM_GROUP}|g" /etc/php7/php-fpm.conf && \
    sed -i "s|;log_level\s*=\s*notice|log_level = notice|g" /etc/php7/php-fpm.conf && \
    sed -i "s|display_errors\s*=\s*Off|display_errors = ${PHP_DISPLAY_ERRORS}|i" /etc/php7/php.ini && \
    sed -i "s|display_startup_errors\s*=\s*Off|display_startup_errors = ${PHP_DISPLAY_STARTUP_ERRORS}|i" /etc/php7/php.ini && \
    sed -i "s|error_reporting\s*=\s*E_ALL & ~E_DEPRECATED & ~E_STRICT|error_reporting = ${PHP_ERROR_REPORTING}|i" /etc/php7/php.ini && \
    sed -i "s|;*memory_limit =.*|memory_limit = ${PHP_MEMORY_LIMIT}|i" /etc/php7/php.ini && \
    sed -i "s|;*upload_max_filesize =.*|upload_max_filesize = ${PHP_MAX_UPLOAD}|i" /etc/php7/php.ini && \
    sed -i "s|;*max_file_uploads =.*|max_file_uploads = ${PHP_MAX_FILE_UPLOAD}|i" /etc/php7/php.ini && \
    sed -i "s|;*post_max_size =.*|post_max_size = ${PHP_MAX_POST}|i" /etc/php7/php.ini && \
    sed -i "s|;opcache.validate_timestamps=.*|opcache.validate_timestamps=0|i" /etc/php7/php.ini && \
    sed -i "s|;*cgi.fix_pathinfo=.*|cgi.fix_pathinfo= ${PHP_CGI_FIX_PATHINFO}|i" /etc/php7/php.ini

ENV TIMEZONE "Europe/Madrid"

RUN cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && \
    echo "${TIMEZONE}" > /etc/timezone && \
    sed -i "s|;*date.timezone =.*|date.timezone = ${TIMEZONE}|i" /etc/php7/php.ini

WORKDIR /var/www
RUN git clone https://github.com/ampache/ampache.git
WORKDIR /var/www/ampache

RUN wget https://getcomposer.org/installer
RUN php installer --install-dir=/usr/local/bin --filename=composer && composer global require hirak/prestissimo
RUN composer install --prefer-source --no-interaction

ADD init.sh /
RUN chmod 777 /init.sh
ADD supervisord.conf /etc/supervisord.conf

ENV MYSQL_HOST "db"
ENV MYSQL_DB "ampache"
ENV MYSQL_ROOT_USER "root"
ENV MYSQL_ROOT_PASSWORD "lalala"
ENV MYSQL_USER "ampache"
ENV MYSQL_PASSWORD "ampache"
ENV MYSQL_PORT "3306"
ENV AMPACHE_USER "ampache"
ENV AMPACHE_PASSWORD "ampache"
#BE CAREFUL, WITH THIS YOU WILL DELETE YOUR DB
ENV FORCE_INSTALL "false"

RUN cp config/ampache.cfg.php.dist config/ampache.cfg.php
RUN chmod 777 -R config
#RUN chmod 600 config/ampache.cfg.php.dist

RUN sed -i "s|;http_host = \"localhost\"|http_host = \"${VIRTUAL_HOST}\"|i" config/ampache.cfg.php && \
    sed -i "s|database_hostname = localhost|database_hostname = ${MYSQL_HOST}|i" config/ampache.cfg.php && \
    sed -i "s|;database_port = 3306|database_port = ${MYSQL_PORT}|i" config/ampache.cfg.php && \
    sed -i "s|database_name = ampache|database_name = ${MYSQL_DB}|i" config/ampache.cfg.php && \
    sed -i "s|database_username = username|database_username = ${MYSQL_USER}|i" config/ampache.cfg.php && \
    sed -i "s|database_password = password|database_password = ${MYSQL_PASSWORD}|i" config/ampache.cfg.php && \
    sed -i "s|;debug = \"false\"|debug = \"true\"|i" config/ampache.cfg.php && \
    sed -i "s|debug_level = 5|debug_level = 5|i" config/ampache.cfg.php && \
    sed -i "s|;log_path = \"/var/log/ampache\"|log_path = \"/var/log/ampache\"|i" config/ampache.cfg.php && \
    sed -i "s|log_filename = \"%name.%Y%m%d.log\"|log_filename = \"error.log\"|i" config/ampache.cfg.php

RUN ln -sf /dev/stdout /var/log/nginx/ampache_access.log && ln -sf /dev/stderr /var/log/nginx/ampache_error.log
RUN ln -sf /dev/stderr /var/log/php7/error.log
RUN mkdir /var/log/ampache -p && ln -sf /dev/stderr /var/log/ampache/error.log
ADD install.php bin/install
ENTRYPOINT /init.sh
