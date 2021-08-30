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
    # For file edits
    vim

