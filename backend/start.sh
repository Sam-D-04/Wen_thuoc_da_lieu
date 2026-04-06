#!/usr/bin/env bash

composer install --no-dev --optimize-autoloader

php artisan key:generate
php artisan config:cache
php artisan route:cache

php artisan migrate --force

php artisan serve --host=0.0.0.0 --port=10000

