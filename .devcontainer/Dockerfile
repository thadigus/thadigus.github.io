FROM ruby:latest

# Create and copy necessary files
COPY ./ /code
WORKDIR /code

# Expose port 4000 for dev site
EXPOSE 4000/tcp

# Use bundle to install dependencies
RUN bundle install

# Default running command to serve Jekyll server
CMD ["bundle", "exec", "jekyll", "serve"]
