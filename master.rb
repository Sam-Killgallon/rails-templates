after_bundle do
  git :init
  git add: '.'
  git commit: "-a -m 'Initial commit'"
end

###### GEMS START ######
gem_group :development do
  gem "standard"
end

gem_group :development, :test do
  gem "pry-byebug"
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
  version: '3.7'

  volumes:
    postgres_data:

  services:
    web:
      build:
        context: .
      environment:
        DATABASE_HOST: postgres
        DATABASE_USERNAME: postgres
        DATABASE_PASSWORD: password
      ports:
        - '3000:3000'
      volumes:
        - .:/app
      depends_on:
        - postgres
        - webpack_dev_server

    postgres:
      image: postgres:13.4
      environment:
        POSTGRES_PASSWORD: password
      volumes:
        - postgres_data:/var/lib/postgresql/data

    webpack_dev_server:
      command: ./bin/webpack-dev-server
      build: .
      #environment:
        #WEBPACKER_DEV_SERVER_HOST: '0.0.0.0'
      ports:
        - '3035:3035'
      volumes:
        - .:/app
YAML

file "Dockerfile", <<~DOCKERFILE
  FROM ruby:3
  RUN curl -sL https://deb.nodesource.com/setup_16.x | bash - && \
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list && \
    apt-get update && \
    apt-get install -yf \
      # For running javascript
      nodejs \
      # For javascript package installation
      yarn \
      # For the database
      postgresql-client \
      # For building native extensions
      build-essential \
      # For chromedriver, which gets installed by the 'chromedriver-helper' gem
      libnss3 \
      # For browser tests
      chromium \
      # For file edits
      vim

  RUN mkdir -p /app
  WORKDIR /app

  # Copy the Gemfile as well as the Gemfile.lock and install
  # the RubyGems. This is a separate step so the dependencies
  # will be cached unless changes to one of those two files
  # are made.
  COPY Gemfile Gemfile.lock ./
  RUN gem install bundler && bundle install --frozen && rm /usr/local/bundle/config

  # Copy the main application.
  COPY . ./

  # Do some startup work
  ENTRYPOINT ["docker_scripts/entrypoint.sh"]

  # Will bind to PORT environment variable, or 3000 by default
  CMD ["rails", "server"]
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
