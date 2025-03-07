require "http"
require "json"
require "dry/monads"

module Factiva
  class Request
    include Dry::Monads[:result]

    private_class_method :new
    attr_reader :auth

    def self.search(**args)
      instance.search(**args)
    end

    def self.profile(profile_id)
      instance.profile(profile_id)
    end

    def self.stub!(search: {}, profile: {})
      @instance = MockedRequest.new(search, profile)
      true
    end

    def self.unstub!
      @instance = nil
      true
    end

    class MockedRequest
      attr_reader :stubbed_search, :stubbed_profile

      def initialize(stubbed_search, stubbed_profile)
        @stubbed_search  = stubbed_search
        @stubbed_profile = stubbed_profile
      end

      def search(first_name: nil, last_name: nil, birth_date: nil, birth_year: nil,
                 birth_month: nil, birth_day: nil, exclude_pep: false, offset: 0, limit: 200)
        stubbed_search
      end

      def profile(id = nil)
        stubbed_profile
      end
    end

    def initialize
      set_auth
    end

    def search(first_name:, last_name:, birth_date: nil, birth_year: nil,
               birth_month: nil, birth_day: nil, exclude_pep: false, offset: 0, limit: 200)

      # Birth date takes priority over year, month and day values
      if birth_date
        birth_year, birth_month, birth_day = [
          birth_date.year.to_s,
          birth_date.month.to_s,
          birth_date.day.to_s
        ]
      end

      params = { json: search_body(
        first_name,
        last_name,
        birth_year,
        birth_month,
        birth_day,
        exclude_pep,
        offset,
        limit
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
      @auth = Authentication.new(config)
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
          .timeout(config.timeout)
          .auth("Bearer #{auth.token}")
          .send(*http_params)

        response_body = JSON.parse(response.body.to_s)

        if response.status.success?
          Success(response_body)
        else
          Failure({ code: response.code, error: response_body["error"] }.to_s)
        end
      rescue HTTP::TimeoutError
        # This error should be handled before HTTP::Error which is a superclass of HTTP::TimeoutError
        # Raising Factiva::TimeoutError is required for CircuitBreaker to work properly
        raise Factiva::TimeoutError
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

    def search_body(first_name, last_name, birth_year, birth_month, birth_day, exclude_pep, offset, limit)
      base = {
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
                  "search_type" => "Precise"
                },
                "date_of_birth" => date_search_filter(
                  birth_year,
                  birth_month,
                  birth_day
                )
              },
              "group_operator" => "And"
            },
            "filter_group_or": {
              "filters": {
                  "occupation_category": {
                      "is_all_excluded": exclude_pep,
                      "operator": "Or"
                  }
              },
              "group_operator": "Or"
            }
          }
        }
      }
    end

    def date_search_filter(year, month, day)
      return nil if [year, month, day].all? { |value| value.nil? }

      date_filter = {
        "date" => {
          "is_strict_match" => true
        }
      }

      date_filter["date"]["year"]  = year  if year
      date_filter["date"]["month"] = month if month
      date_filter["date"]["day"]   = day   if day
      date_filter
    end

    def config
      Factiva.configuration(Factiva::REQUEST_API_ACCOUNT)
    end
  end
end
