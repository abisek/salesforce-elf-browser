FROM ruby:2.3
MAINTAINER ViViDboarder <ViViDboarder@gmail.com>
# Install node for asset building
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs
# Create and switch to a user called app
RUN useradd -ms /bin/bash app
WORKDIR /home/app
COPY Gemfile Gemfile.lock /home/app/
RUN bundle install
ADD . /home/app
RUN chown -R app:app /home/app
USER app

EXPOSE 8080
CMD ["bundle","exec","rackup","--host","0.0.0.0","-p","8080"]
