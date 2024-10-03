require "dry/monads"

module Factiva
  class Client
    include Dry::Monads[:result]

    attr_reader :config, :auth

    def initialize(config)
      @config = config
      @auth = nil
    end

    def set_auth!
      @auth = Authentication.new(config)
    end

    def make_authorized_request(...)
      make_request(...)
        .or       { set_auth!; make_request(...) }
        .value_or { |error| raise RequestError.new(error) }
    end

    def make_authentication_request(...)
      make_request(...)
        .value_or { |error| raise RequestError.new(error) }
    end

  private

    def make_request(http_method, url, params = nil)
      http_params = [http_method, url, params].compact

      begin
        request = HTTP
          .headers(:accept => "application/json")
          .headers("Content-Type" => "application/json")
          .timeout(config.timeout)

        request.auth("Bearer #{auth.token}") if auth

        response = request.send(*http_params)

        response_body = JSON.parse(response.body.to_s)

        if response.status.success?
          Success(response_body)
        else
          Failure({ code: response.code, error: response_body["error"] }.to_s)
        end
      rescue HTTP::TimeoutError
        # This error should be handled before HTTP::Error which is a superclass of HTTP::TimeoutError
        # Raising HTTP::TimeoutError is required for CircuitBreaker to work properly
        raise
      rescue SocketError, HTTP::Error => error
        Failure("Failed to connect to Factiva: #{error.message}")
      rescue JSON::ParserError => error
        Failure(error.message)
      end
    end
  end
end
