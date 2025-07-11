FROM ruby:3.1.2

# Install the application dependencies
COPY ./ /code
WORKDIR /code

# RUN adduser jekyll
# USER jekyll

RUN bundle install

EXPOSE 4000/tcp

CMD ["bundle", "exec", "jekyll", "serve"]