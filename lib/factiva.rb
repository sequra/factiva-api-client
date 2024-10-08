Dir[File.join(__dir__, "factiva", "*.rb")].each { |file| require file }

module Factiva

  REQUEST_API_ACCOUNT = "request_api_account"
  MONITORING_API_ACCOUNT = "monitoring_api_account"

  def self.configuration(account = REQUEST_API_ACCOUNT)
    @configuration ||= {}
    @configuration[account] ||= Configuration.new
  end

  def self.configure(account = REQUEST_API_ACCOUNT)
    yield(configuration(account))
  end
end
