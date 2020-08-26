FROM php:7.3-apache-buster
MAINTAINER Ant
ENV DEBIAN_FRONTEND=noninteractive

# Install components
RUN apt-get update -y && apt-get install -y \
		curl \
        vim \
        git \
		git-core \
		gzip \
		openssh-client \
		unzip \
		zip \
	--no-install-recommends && \
	apt-get autoremove -y && \
	rm -rf /var/lib/apt/lists/* && \
    docker-php-ext-install -j$(nproc) \
		bcmath \
		mysqli \
		pdo \
		pdo_mysql && \
    apt-get update -y && apt-get install -y \
		zlib1g-dev \
        libicu-dev \
        g++ \
        libldap2-dev \
        libgd-dev \
        libzip-dev \
        libtidy-dev \
        libxml2-dev \
        libxslt-dev \
    --no-install-recommends && \
    apt-mark auto \
        zlib1g-dev \
        libicu-dev \
        g++ \
        libldap2-dev \
        libxml2-dev \
        libxslt-dev && \
    curl -sS https://silverstripe.github.io/sspak/install | php -- /usr/local/bin && \
    pecl install xdebug && \
    docker-php-ext-configure intl && \
    docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ && \
    docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ && \
    docker-php-ext-install -j$(nproc) \
        intl \
        ldap \
        gd \
        soap \
        tidy \
        xsl \
        zip && \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false && \
	rm -rf /var/lib/apt/lists/* && \
    { \
            echo "<VirtualHost *:80>"; \
            echo "  DocumentRoot /var/www/html/ss_project/public"; \
            echo "  LogLevel warn"; \
            echo "  ErrorLog /var/log/apache2/error.log"; \
            echo "  CustomLog /var/log/apache2/access.log combined"; \
            echo "  ServerSignature Off"; \
            echo "  <Directory /var/www/html/ss_project/public>"; \
            echo "    Options +FollowSymLinks"; \
            echo "    Options -ExecCGI -Includes -Indexes"; \
            echo "    AllowOverride all"; \
            echo; \
            echo "    Require all granted"; \
            echo "  </Directory>"; \
            echo "  <LocationMatch assets/>"; \
            echo "    php_flag engine off"; \
            echo "  </LocationMatch>"; \
            echo; \
            echo "  IncludeOptional sites-available/000-default.local*"; \
            echo "</VirtualHost>"; \
	} | tee /etc/apache2/sites-available/000-default.conf && \
    echo "ServerName 172.18.0.3" > /etc/apache2/conf-available/fqdn.conf && \
	echo "date.timezone = Pacific/Auckland" > /usr/local/etc/php/conf.d/timezone.ini && \
    echo "log_errors = On\nerror_log = /dev/stderr" > /usr/local/etc/php/conf.d/errors.ini && \
	a2enmod rewrite expires remoteip cgid && \
	usermod -u 1000 www-data && \
	usermod -G staff www-data \
    && cd /var/www/html/ \
    && git clone https://github.com/ant1234/ss_project.git \
    && curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer \
    && cd /var/www/html/ss_project \
    && composer install \
    && chown -R www-data:www-data public/assets public/assets/.htaccess;

EXPOSE 80
CMD ["apache2-foreground"]
