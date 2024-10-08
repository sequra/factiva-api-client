module Factiva
  class Error < StandardError; end
  class RequestError < Error; end
  class TimeoutError < Error; end
end
