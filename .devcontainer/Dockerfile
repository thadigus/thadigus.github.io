FROM ruby:latest

# Copy only the gem manifests; the workspace folder is the mounted PVC
COPY Gemfile Gemfile.lock /build/
WORKDIR /build

# Use bundle to install dependencies
RUN bundle install

# Expose port 4000 for dev site
EXPOSE 4000
EXPOSE 35729

WORKDIR /workspaces/thadigus-blog
# Default running command to serve Jekyll server
CMD ["bundle", "exec", "jekyll", "serve", "--host", "0.0.0.0", "--port", "4000", "--livereload"]
