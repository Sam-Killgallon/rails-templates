# TODO:
# Add socket setup to database.yml to support remote postgres
# Add CI files
# Fix issue with the default webpack-dev-server install not working with current version of webpacker

###### GEMS START ######
gem_group :development do
  gem "standard"
end

gem_group :development, :test do
  gem "pry-byebug"
  gem "debug", ">= 1.0.0.beta8"
end

gem "pry-rails"

file ".standard.yml", <<~YAML
  fix: true
  parallel: true
  ignore:
    - db/schema.rb
YAML
###### GEMS END ######

###### DOCKER START ######
file "docker-compose.yml", <<~YAML
  version: '3.8'

  volumes:
    postgres_data:

  x-rails-app: &rails-app
    build: .
    environment:
      DATABASE_HOST: postgres
      DATABASE_USERNAME: postgres
      DATABASE_PASSWORD: password
    volumes:
      - .:/app
    # To support pry debugging
    tty: true
    stdin_open: true

  services:
    app:
      <<: *rails-app
      ports:
        - '3000:3000'
      depends_on:
        - postgres
        - webpack_dev_server

    webpack_dev_server:
      command: ./bin/webpack-dev-server
      <<: *rails-app
      #environment:
        #WEBPACKER_DEV_SERVER_HOST: '0.0.0.0'
      ports:
        - '3035:3035'

    postgres:
      image: postgres:13.4
      environment:
        POSTGRES_PASSWORD: password
      volumes:
        - postgres_data:/var/lib/postgresql/data

YAML

file "Dockerfile", <<~DOCKERFILE, mode: 0x744
  FROM ruby:3
  RUN curl -sL https://deb.nodesource.com/setup_14.x | bash - && \\
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \\
    echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list && \\
    apt-get update && \\
    apt-get install -yf \\
      # For copying files into the cache
      rsync \\
      # For running javascript
      nodejs \\
      # For javascript package installation
      yarn \\
      # For the database
      postgresql-client \\
      # For building native extensions
      build-essential \\
      # For chromedriver, which gets installed by the 'chromedriver-helper' gem
      libnss3 \\
      # For browser tests
      chromium \\
      # For file edits
      vim

  RUN mkdir -p /app
  WORKDIR /app

  COPY package.json yarn.lock ./
  RUN --mount=target=/app/node_modules,type=cache \\
      yarn install

  # Copy the Gemfile as well as the Gemfile.lock and install
  # the RubyGems. This is a separate step so the dependencies
  # will be cached unless changes to one of those two files
  # are made.
  COPY Gemfile Gemfile.lock ./
  RUN --mount=target=/bundle-tmp/,type=cache \\
      gem install bundler && \\
      bundle install --path /bundle-tmp/ && \\
      rsync -a /bundle-tmp/ruby/3.0.0/ /usr/local/bundle/ && \\
      rm /usr/local/bundle/config

  # Copy the main application.
  COPY . ./

  # Do some startup work
  ENTRYPOINT ["docker_scripts/entrypoint.sh"]

  # Will bind to PORT environment variable, or 3000 by default
  CMD ["rails", "server", "-b", "0.0.0.0"]
DOCKERFILE

file ".dockerignore", <<~DOCKERIGNORE
  # Ignore bundler config.
  /.bundle

  # Ignore all logfiles and tempfiles.
  /log/*
  /tmp/*
  !/log/.keep
  !/tmp/.keep

  # Ignore uploaded files in development.
  /storage/*
  !/storage/.keep

  /public/assets
  /public/packs*
  /node_modules
  yarn-error.log
  yarn-debug.log*
  .yarn-integrity
  .byebug_history

  # Ignore master key for decrypting credentials and more.
  /config/master.key
  /config/credentials/*.key

  /Dockerfile
  /.git*
  /spec
DOCKERIGNORE

file "docker_scripts/entrypoint.sh", <<~BASH
  #!/bin/bash
  set -euo pipefail

  # Pid files can get left over if the container doesn't exist cleanly which
  # prevents the app from starting
  rm -rf tmp/pids/*.pid
  exec "$@"
BASH
###### DOCKER END ######

###### CI START ######
# Add linting
# Add test runs
###### CI END ######
