require "http"
require "json"
require "dry/monads"

module Factiva
  class Request
    include Dry::Monads[:result]

    private_class_method :new
    attr_reader :auth

    def self.search(*args)
      instance.search(*args)
    end

    def self.profile(*args)
      instance.profile(*args)
    end

    def initialize
      set_auth
    end

    def search(first_name:, last_name:)
      params = { json: search_body(
        first_name: first_name,
        last_name: last_name
      ) }

      # If the request fails auth is reset and the request retried
      post(search_url, params)
        .or       { set_auth; post(search_url, params) }
        .value_or { |error| raise RequestError.new(error) }
    end

    def profile(profile_id)
      url = profile_url(profile_id)

      # If the request fails auth is reset and the request retried
      get(url)
        .or       { set_auth; get(url) }
        .value_or { |error| raise RequestError.new(error) }
    end

  private
    def self.instance
      @instance ||= new
    end

    def set_auth
      @auth = Authentication.new
    end

    def post(url, params)
      make_request(:post, url, params)
    end

    def get(url)
      make_request(:get, url)
    end

    def make_request(method, url, params = nil)
      http_params = method == :post ? [:post, url, params] : [:get, url]

      begin
        response = HTTP
          .auth("Bearer #{auth.token}")
          .send(*http_params)

        response_body = JSON.parse(response.body.to_s)

        if response.status.success?
          Success(response_body)
        else
          Failure({ code: response.code, error: response_body["error"] }.to_s)
        end
      rescue SocketError, HTTP::Error => error
        Failure("Failed to connect to Factiva: #{error.message}")
      rescue JSON::ParserError => error
        Failure(error.message)
      end
    end

    def search_url
      @search_url ||= make_url("riskentities/search")
    end

    def profile_url(profile_id)
      make_url("riskentities/profiles/#{profile_id}")
    end

    def make_url(suffix)
      url = config.base_url
      url = url.delete_suffix("/") if url.end_with?("/")

      "#{url}/#{suffix}"
    end

    def search_body(first_name:, last_name:, offset: 0, limit: 200)
      {
        "data" => {
          "type" => "RiskEntitySearch",
          "attributes" => {
            "paging" => {
              "offset" => offset,
              "limit" => limit
            },
            "sort" => nil,
            "filter_group_and" => {
              "filters" => {
                "content_set" => [
                  "Watchlist"
                ],
                "record_types" => [
                  "Person"
                ],
                "person_name" => {
                  "first_name" => first_name,
                  "last_name" => last_name,
                  "search_type" => "Broad"
                }
              },
              "group_operator" => "And"
            }
          }
        }
      }
    end

    def config
      Factiva.configuration
    end
  end
end
