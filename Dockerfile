FROM php:7.2-cli

MAINTAINER mak <xiaomak@qq.com>

###更新apt-get源 使用163的源
RUN mv /etc/apt/sources.list /etc/apt/sources.list.bak && \
    echo "deb http://mirrors.163.com/debian/ stretch main non-free contrib" >/etc/apt/sources.list && \
    echo "deb http://mirrors.163.com/debian/ stretch-updates main non-free contrib" >>/etc/apt/sources.list && \
    echo "deb http://mirrors.163.com/debian/ stretch-backports main non-free contrib" >>/etc/apt/sources.list && \
    echo "deb-src http://mirrors.163.com/debian/ stretch main non-free contrib" >>/etc/apt/sources.list && \
    echo "deb-src http://mirrors.163.com/debian/ stretch-updates main non-free contrib" >>/etc/apt/sources.list && \
    echo "deb-src http://mirrors.163.com/debian/ stretch-backports main non-free contrib" >>/etc/apt/sources.list && \
    echo "deb http://mirrors.163.com/debian-security/ stretch/updates main non-free contrib" >>/etc/apt/sources.list && \
    echo "deb-src http://mirrors.163.com/debian-security/ stretch/updates main non-free contrib" >>/etc/apt/sources.list

RUN cat /etc/apt/sources.list

# Install modules : GD iconv
RUN apt-get update && apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        openssl \
        libssh-dev \
        libnghttp2-dev \
        libhiredis-dev \
        libpcre3 \
        libpcre3-dev \
        autoconf \
        make \
    && docker-php-ext-install iconv \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install gd

# install php pdo_mysql opcache
# WARNING: Disable opcache-cli if you run you php
RUN docker-php-ext-install pdo_mysql mysqli iconv mbstring json opcache && \
    echo "opcache.enable_cli=0" >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini

#install redis
RUN pecl install redis && docker-php-ext-enable redis

# install composer
ENV COMPOSER_ALLOW_SUPERUSER 1
RUN curl -sS https://getcomposer.org/installer | php && \
mv composer.phar /usr/local/bin/composer && \
composer config -g repo.packagist composer https://packagist.phpcomposer.com && \
composer self-update --clean-backups && \
apt-get install -y zip unzip

# install swoole
#TIP: it always get last stable version of swoole coroutine.
RUN cd /root && \
    curl -o /tmp/swoole-releases https://github.com/swoole/swoole-src/releases -L && \
    cat /tmp/swoole-releases | grep 'href=".*v2.*.tar.gz"' | head -1 | \
    awk -F '"' ' {print "curl -o /tmp/swoole.tar.gz https://github.com"$2" -L" > "/tmp/swoole.download"}' && \
    sh /tmp/swoole.download && \
    tar zxvf /tmp/swoole.tar.gz && cd swoole-src* && \
    phpize && \
    ./configure \
    --enable-coroutine \
    --enable-openssl  \
    --enable-http2  \
    --enable-async-redis \
    --enable-mysqlnd && \
    make && make install && \
    docker-php-ext-enable swoole && \
    echo "swoole.fast_serialize=On" >> /usr/local/etc/php/conf.d/docker-php-ext-swoole-serialize.ini && \
    rm -rf /tmp/*

# set China timezone
RUN /bin/cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo 'Asia/Shanghai' > /etc/timezone && \
    echo "[Date]\ndate.timezone=Asia/Shanghai" > /usr/local/etc/php/conf.d/timezone.ini