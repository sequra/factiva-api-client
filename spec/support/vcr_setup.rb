# frozen_string_literal: true

require "vcr"

VCR.configure do |c|
  c.cassette_library_dir = "spec/vcr"
  c.hook_into :webmock
  c.configure_rspec_metadata!
  c.allow_http_connections_when_no_cassette = false
  c.ignore_localhost = true
  c.filter_sensitive_data("<SECRET_CLIENT_ID>") { Factiva.configuration.client_id }
  c.filter_sensitive_data("<SECRET_PASSWORD>") { Factiva.configuration.password }
  c.filter_sensitive_data("<SECRET_USERNAME>") { URI.encode_www_form_component(Factiva.configuration.username) }
end
