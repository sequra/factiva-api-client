require "http"
require "json"

module Factiva
  class RequestError < Exception; end

  class Authentication
    def token
      authz["access_token"]
    end

  private
    def authn
      @authn ||= set_authn
    end

    def authz
      @authz ||= set_authz
      @authz = set_authz(refresh: true) if expired?(@authz["expiration_timestamp"])
      @authz
    end

    def set_authn
      make_request(set_authn_params)
    end

    def set_authz(refresh: false)
      params = refresh ? refresh_authz_params : set_authz_params

      new_authz = make_request(params)
      new_authz["expiration_timestamp"] = Time.now + new_authz["expires_in"]
      new_authz
    end

    def make_request(params)
      response = HTTP.post(
        url,
        params
      )

      response_body = JSON.parse(response.body.to_s)

      if !response.status.success?
        raise RequestError.new({ code: response.code, error: response_body["error"] }.to_s)
      end

      response_body
    end

    def expired?(timestamp)
      timestamp < Time.now
    end

    def set_authn_params
      {
        form: {
          client_id: config.client_id,
          connection: config.connection,
          grant_type: config.authn_grant_type,
          password: config.password,
          scope: config.authn_scope,
          username: config.username,
          device: config.device
        }
      }
    end

    def set_authz_params
      {
        form: {
          assertion: authn["id_token"],
          client_id: config.client_id,
          grant_type: config.authz_grant_type,
          scope: config.authz_scope
        }
      }
    end

    def refresh_authz_params
      {
        json: {
          client_id: config.client_id,
          grant_type: config.refresh_authz_grant_type,
          refresh_token: authn["refresh_token"],
          scope: config.authn_scope
        }
      }
    end

    def url
      @url ||= make_url
    end

    def make_url
      url = config.base_url
      url = url.delete_suffix("/") if url.end_with?("/")

      "#{url}/token"
    end

    def config
      Factiva.configuration
    end
  end
end