FROM node:8 AS node
FROM php:7.2
COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /opt/yarn /opt/yarn
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN cd /usr/local/bin; ln -sf ../lib/node_modules/npm/bin/npm-cli.js npm; ln -sf /opt/yarn/bin/yarn yarn; chmod +x npm; chmod +x yarn
ADD setup /tmp/setup
RUN php /tmp/setup --install-dir=/usr/local/bin --filename=composer; rm -f /tmp/setup

