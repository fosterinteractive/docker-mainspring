# Build the node image and store the build as node. We need to name it because
# when we call FROM again it will clear out the previous build.
FROM node:16.19 AS node

# RUN npm install -g npm@9.4.1

# Install gulp globally
RUN npm install -g gulp-cli

# Build stage using php image.
FROM php:8.1-cli

RUN groupadd -r dev && useradd -g dev -m dev

# Install some needed packages then after install remove the cache files of
# apt-get to save space.
RUN apt-get update && apt-get install -y \
  git \
  libpng-dev \
  rsync \
  unzip \
  zip \
  zlib1g-dev \
  libzip-dev \
  && rm -rf /var/lib/apt/lists/*

# Create seperate config.ini files for overriding the php settings to set the
# php memory limit to no limit (needed for composer) and set the timezone to 
# UTC if the PHP_TIMEZONE environment variable is undefined.
#
# This avoids having to have a php.ini file and will just use the defaults set
# in php.
RUN echo "memory_limit=-1" > "$PHP_INI_DIR/conf.d/memory-limit.ini" \
 && echo "date.timezone=${PHP_TIMEZONE:-UTC}" > "$PHP_INI_DIR/conf.d/date_timezone.ini"

# Install some needed php extensions.
RUN docker-php-ext-install zip gd

# Copy node.js from the node stage into the current stage as well will run our
# builds in this stage.
COPY --from=node /usr/local/bin/node /usr/local/bin/node

# Set the yarn version environment version from the node stage. Yarn comes with
# the node image by default so no reason to download it.
ENV YARN_VERSION 1.22.19
ENV npm_config_cache /home/dev/.npm

# Copy yarn from the node stage to this stage.
COPY --from=node /opt/yarn-v$YARN_VERSION /opt/yarn

# Copy the node modules from the node stage to this stage.
COPY --from=node /usr/local/lib/node_modules /home/dev/.npm-global

RUN chown -R dev:dev /home/dev
# Symlink all of the needed node apps into our user bin so they can be 
# executable and update the apps permissions.
RUN cd /usr/local/bin; \
  ln -sf /home/dev/.npm-global/npm/bin/npm-cli.js npm; \
  ln -sf /home/dev/.npm-global/gulp-cli/bin/gulp.js gulp; \
  ln -sf /opt/yarn/bin/yarn yarn; \
  chmod +x npm; \
  chmod +x yarn; \
  chmod +x gulp

# Set some environment variables for composer and drush.
ENV COMPOSER_ALLOW_SUPERUSER 1
ENV DRUSH_VERSION 10.4.3
# ENV TERMINUS_PLUGINS_DIR /usr/local/share/terminus-plugins

# Copy our scripts folder into the tmp folder of this container.
COPY scripts /tmp/scripts/

# Install composer and add it's vendor bin folder to the exports path in the
# bash file so we can execute the apps from cmd line.
RUN curl -sS https://getcomposer.org/installer | php -- --version=2.1.3 \
    && mv composer.phar /usr/local/bin/composer \
    && echo "export PATH=~/.composer/vendor/bin:\$PATH" >> ~/.bash_profile

# Run the drush setup script that will install drush.
RUN /tmp/scripts/drush-setup
# Run the terminus plugins setup script.
RUN /tmp/scripts/terminus-plugins-setup
