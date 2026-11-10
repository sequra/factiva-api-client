require "json"
require "dry/monads"

module Factiva
  module Response
    extend Dry::Monads[:result]

    def self.to_result(response)
      raw_body = response.body.to_s
      body = raw_body.empty? ? {} : JSON.parse(raw_body)
      return Success(body) if response.status.success?

      Failure({ code: response.code, error: error_detail(body) })
    rescue JSON::ParserError
      Failure({ code: response.code, error: raw_body })
    end

    def self.error_detail(body)
      body.is_a?(Hash) ? body["error"] || body["errors"] : body
    end

    private_class_method :error_detail
  end
end
