# frozen_string_literal: true

# Replace "dummy_" values for real ones in order
# to record from scratch vcr cassetes
Factiva.configure do |config|
  config.auth_url = "https://accounts.dowjones.com/oauth2/v1/token"
  config.base_url = "https://api.dowjones.com"
  config.client_id = "dummy_client_id"
  config.password = "dummy_password"
  config.username = "dummy_username"
  config.device = "testdevice"
end
