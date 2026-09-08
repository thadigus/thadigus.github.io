FROM ruby:latest

# Create and copy necessary files
COPY ./ /workspaces/thadigus-blog
WORKDIR /workspaces/thadigus-blog

# Expose port 4000 for dev site
EXPOSE 4000
EXPOSE 35729

# Use bundle to install dependencies
RUN bundle install

# Default running command to serve Jekyll server
CMD ["bundle", "exec", "jekyll", "serve", "--host", "0.0.0.0", "--port", "4000", "--livereload"]
