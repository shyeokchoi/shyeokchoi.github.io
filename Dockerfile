# Use the official Ruby image as base
FROM ruby:3.2-alpine

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apk add --no-cache \
    build-base \
    gcc \
    musl-dev \
    libffi-dev \
    nodejs \
    npm \
    git

# Copy Gemfile, Gemfile.lock, and gemspec file first for better caching
COPY Gemfile Gemfile.lock minimal-mistakes-jekyll.gemspec ./

# Install Ruby gems
RUN bundle install

# Copy the rest of the application
COPY . .

# Expose port 4000 (Jekyll's default port)
EXPOSE 4000

# Set the default command to run Jekyll serve
CMD ["bundle", "exec", "jekyll", "serve", "--host", "0.0.0.0", "--port", "4000"] 