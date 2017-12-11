FROM node:8 AS node
FROM php:7.2
COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /opt/yarn /opt/yarn
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN cd /usr/local/bin; ln -sf ../lib/node_modules/npm/bin/npm-cli.js npm; ln -sf /opt/yarn/bin/yarn yarn; chmod +x npm; chmod +x yarn
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"; php -r "if (hash_file('SHA384', 'composer-setup.php') === '544e09ee996cdf60ece3804abc52599c22b1f40f4323403c44d44fdfdd586475ca9813a858088ffbc1f233e9b180f061') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"; php composer-setup.php --install-dir=/usr/local/bin --filename=composer; php -r "unlink('composer-setup.php');"
