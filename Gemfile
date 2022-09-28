# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in factiva-api-client.gemspec
gemspec

gem "rake", "~> 13.0"

group :development, :test do
  gem "pry", "~> 0.14.1"
  gem "rspec", "~> 3.0"
  gem "sequra-style", "~> 0.1", git: "https://github.com/sequra/sequra-style", require: false
end

group :test do
  gem "vcr", "~> 6.0"
  gem "webmock", "~> 3.0"
end
