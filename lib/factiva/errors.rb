module Factiva
  class Error < StandardError; end

  class RequestError < Error
    attr_reader :status_code, :error_body

    def self.from_response(error)
      if error.is_a?(Hash)
        new(error.to_s, status_code: error[:code], error_body: error[:error])
      else
        new(error.to_s)
      end
    end

    def initialize(message = nil, status_code: nil, error_body: nil)
      @status_code = status_code
      @error_body = error_body
      super(message)
    end
  end

  class TimeoutError < Error; end
end
