# frozen_string_literal: true

# Replace "dummy_" values for real ones in order
# to record from scratch vcr cassettes
Factiva.configure do |config|
  config.auth_url  = "https://accounts.dowjones.com/oauth2/v1/token"
  config.base_url  = "https://api.dowjones.com"
  config.timeout   = 5 # seconds
  config.client_id = "dummy_client_id"
  config.password  = "dummy_password"
  config.username  = "dummy_username"
  config.device    = "testdevice"
end

Factiva.configure(Factiva::MONITORING_API_ACCOUNT) do |config|
  config.auth_url  = "https://accounts.dowjones.com/oauth2/v1/token"
  config.base_url  = "https://api.dowjones.com"
  config.timeout   = 5 # seconds
  config.client_id = "monitoring_dummy_client_id"
  config.password  = "monitoring_dummy_password"
  config.username  = "monitoring_dummy_username"
  config.device    = "testdevice"
end
