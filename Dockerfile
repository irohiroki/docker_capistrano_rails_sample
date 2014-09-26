FROM ruby:2.1.3

ADD . /app

WORKDIR /app
RUN bundle install --without="development"
EXPOSE 3000
CMD ["rails", "server"]
