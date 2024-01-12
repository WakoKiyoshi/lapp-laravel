FROM ubuntu:23.04

RUN apt-get update -y
RUN apt-get install -y \
 openssh-server \
 vim \
 unzip \
 git \
 apache2 \
 php8.0 \
 php-cli php-common php-curl php-xml php-soap php-mbstring php-pdo php-pgsql \
 postgresql-client

# SSH
RUN sed -ri 's/^#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
RUN sed -ri 's/^#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN echo 'root:P@SSW0RD' | chpasswd
RUN /etc/init.d/ssh restart

# Copy laravel source
COPY . /root/

# Composer
COPY --from=composer /usr/bin/composer /usr/bin/composer

# Install laravel
RUN cd /var/www/html && /usr/bin/composer create-project laravel/laravel lapp-laravel

# php
RUN cp -r /root/docker-config/php/php.ini /etc/php/8.1/apache2/php.ini

# apache2
RUN rm -rf /etc/apache2/sites-available/*
RUN cp -f /root/docker-config/apache2/lapp-laravel.conf /etc/apache2/sites-available/
RUN cp -f /root/docker-config/apache2/security.conf /etc/apache2/conf-available/
RUN echo ServerName localhost > /etc/apache2/conf-available/fqdn.conf && a2enconf fqdn
RUN a2ensite lapp-laravel.conf
RUN a2enmod rewrite
RUN a2enmod headers
RUN chown www-data:www-data /var/www/html/lapp-laravel
CMD [ "apachectl", "restart" ]

# laravel directories
RUN chown www-data:www-data /var/www/html/lapp-laravel/storage/ -R
RUN chown www-data:www-data /var/www/html/lapp-laravel/bootstrap/cache/ -R

# migrate
WORKDIR /var/www/html/lapp-laravel
#RUN php artisan migrate

#CMD [ "apachectl", "-D", "FOREGROUND" ]
CMD [ "/sbin/init" ]
