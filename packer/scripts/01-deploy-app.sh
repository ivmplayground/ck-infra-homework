#!/bin/bash

cd /var/www/ck-infra-homework/
sudo bundle install
sudo bundle exec rake assets:precompile
sudo chown -R www-data.www-data /var/www/ck-infra-homework/
