FROM ruby:3.1.2

RUN apt-get update -qq && apt-get install -y nodejs postgresql-client

ENV RAILS_ENV 'development'

RUN gem update bundler

RUN mkdir /myapp

WORKDIR /myapp

COPY Gemfile /myapp/Gemfile

COPY Gemfile.lock /myapp/Gemfile.lock

RUN bundle install --jobs 20 --retry 5

COPY docker/docker-entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["rails", "s", "-b", "0.0.0.0"]