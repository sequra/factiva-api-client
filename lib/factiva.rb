Dir[File.join(__dir__, "factiva", "*.rb")].each { |file| require file }

module Factiva
  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end
end
