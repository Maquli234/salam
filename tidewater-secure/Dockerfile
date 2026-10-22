# Tidewater IT website - hardened build
FROM php:8.2-apache

# Apache: headers module on, unneeded modules off, our hardened config
RUN a2enmod headers \
 && (a2dismod -f autoindex negotiation status >/dev/null 2>&1 || true)
COPY docker/tidewater.conf /etc/apache2/conf-available/tidewater.conf
RUN a2enconf tidewater

# PHP: no wrappers, no shell functions, restricted file access, no error display
COPY docker/hardening.ini /usr/local/etc/php/conf.d/zz-hardening.ini

# Site: public files in the web root, application code outside it
RUN rm -rf /var/www/html/*
COPY web/public/ /var/www/html/
COPY web/app/    /var/www/app/
RUN chown -R root:root /var/www/html /var/www/app \
 && find /var/www/html /var/www/app -type d -exec chmod 755 {} \; \
 && find /var/www/html /var/www/app -type f -exec chmod 644 {} \;

# Logs stay symlinked to stdout/stderr (from the base image): there is no log file to include.
# Nothing else is installed: no docker CLI, no python, no extra users, no secrets.

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD php -d allow_url_fopen=1 -d open_basedir= -r 'exit(@file_get_contents("http://127.0.0.1/index.php?page=home") === false ? 1 : 0);'

EXPOSE 80
CMD ["apache2-foreground"]
