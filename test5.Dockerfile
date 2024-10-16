#syntax=docker/dockerfile:1
FROM composer:latest

WORKDIR /var/www/html

RUN --mount=type=secret,id=COMPOSER_AUTH,env=COMPOSER_AUTH,required composer install --no-dev
