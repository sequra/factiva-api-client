module Factiva
  class Configuration
    attr_accessor :auth_url,
                  :base_url,
                  :timeout,
                  :client_id,
                  :password,
                  :username,
                  :device

    attr_reader :connection,
                :authn_grant_type,
                :authz_grant_type,
                :refresh_authz_grant_type,
                :authn_scope,
                :authz_scope

    def initialize
      @connection = "service-account"
      @authn_grant_type = "password"
      @authz_grant_type = "urn:ietf:params:oauth:grant-type:jwt-bearer"
      @refresh_authz_grant_type = "refresh_token"
      @authn_scope = "openid service_account_id offline_access:"
      @authz_scope = "openid pib"
    end
  end
end
