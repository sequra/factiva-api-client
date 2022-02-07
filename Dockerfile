FROM ruby:2.7.5-alpine3.15
RUN apk add --update --no-cache \
  git \
  libcurl \
  build-base

WORKDIR /app
COPY . /app

RUN sh bin/setup
CMD bin/console
