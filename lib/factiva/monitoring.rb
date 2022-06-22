require "http"
require "json"
require "dry/monads"

module Factiva
  class Monitoring
    include Dry::Monads[:result]

    private_class_method :new
    attr_reader :auth

    COUNTRY_IDS = {
      "ES" => "SPAIN",
      "FR" => "FRA",
      "IT" => "ITALY",
      "PT" => "PORL",
    }.freeze

    def self.create_case(*args)
      instance.create_case(*args)
    end

    def self.create_association(*args)
      instance.create_association(*args)
    end

    def self.add_association_to_case(*args)
      instance.add_association_to_case(*args)
    end

    def self.get_matches(*args)
      instance.get_matches(*args)
    end

    def self.log_decision(*args)
      instance.log_decision(*args)
    end

    def self.stub!(create_case: {},
        create_association: {},
        add_association_to_case: {},
        get_matches: {},
        log_decision: {}
        )
      @instance = MockedRequest.new(
        create_case,
        create_association,
        add_association_to_case,
        get_matches,
        log_decision
      )
      true
    end

    def self.unstub!
      @instance = nil
      true
    end

    class MockedRequest
      attr_reader :stubbed_create_case,
      :stubbed_create_association,
      :stubbed_add_association_to_case,
      :stubbed_get_matches,
      :stubbed_log_decision

      def initialize(stubbed_create_case,
        stubbed_create_association,
        stubbed_add_association_to_case,
        stubbed_get_matches,
        stubbed_log_decision
      )
        @stubbed_create_case  = stubbed_create_case
        @stubbed_create_association  = stubbed_create_association
        @stubbed_add_association_to_case  = stubbed_add_association_to_case
        @stubbed_get_matches = stubbed_get_matches
        @stubbed_log_decision = stubbed_log_decision
      end

      def create_case
        stubbed_create_case
      end

      def create_association
        stubbed_create_association
      end

      def add_association_to_case
        stubbed_add_association_to_case
      end

      def get_matches
        stubbed_get_matches
      end

      def log_decision
        stubbed_log_decision
      end
    end

    def initialize
      set_auth
    end

    def create_case
      params = { json: create_case_body }

      # If the request fails auth is reset and the request retried
      post(create_case_url, params)
        .or       { set_auth; post(create_case_url, params) }
        .value_or { |error| raise RequestError.new(error) }
    end

    def create_association(first_name:, last_name:, birth_year:, external_id:, nin:, country_code:)
      params = { json: association_body(
          first_name,
          last_name,
          birth_year,
          external_id,
          nin,
          COUNTRY_IDS.fetch(country_code),
        )
      }

      # If the request fails auth is reset and the request retried
      post(association_url, params)
        .or       { set_auth; post(association_url, params) }
        .value_or { |error| raise RequestError.new(error) }
    end

    def add_association_to_case(case_id:, association_id:)
      params = { json: case_association_body(
          association_id,
        )
      }

      # If the request fails auth is reset and the request retried
      post(case_association_url(case_id), params)
        .or       { set_auth; post(case_association_url(case_id), params) }
        .value_or { |error| raise RequestError.new(error) }
    end

    def get_matches(case_id:)
      # If the request fails auth is reset and the request retried
      get(matches_url(case_id))
        .or       { set_auth; get(matches_url(case_id)) }
        .value_or { |error| raise RequestError.new(error) }
    end

    def log_decision(case_id:, match_id:, comment:, state:, risk_rating:)
      params = { json: log_decision_body(
          comment, state, risk_rating,
        )
      }

      # If the request fails auth is reset and the request retried
      patch(log_decision_url(case_id, match_id), params)
        .or       { set_auth; patch(log_decision_url(case_id, match_id), params) }
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

    def patch(url, params)
      make_request(:patch, url, params)
    end

    def get(url)
      make_request(:get, url)
    end

    def make_request(http_method, url, params = nil)
      http_params = [http_method, url, params].compact

      begin
        response = HTTP
          .headers(:accept => "application/json")
          .headers("Content-Type" => "application/json")
          .timeout(config.timeout)
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

    def make_url(suffix)
      url = config.base_url
      url = url.delete_suffix("/") if url.end_with?("/")

      "#{url}/#{suffix}"
    end

    def create_case_url
      make_url("risk-entity-screening-cases")
    end

    def create_case_body
      {
        "data": {
          "attributes": {
            "case_name": "SeQura-TM",
            "options": {
              "has_to_match_low_quality_alias": false,
              "is_indexed": true,
              "score_threshold": 0.9,
              "search_type": "PRECISE"
            },
            "owner_id": "SeQura",
            "score_preferences": {
              "country": {
                "has_exclusions": false,
                "score": 0
              },
              "gender": {
                "has_exclusions": false,
                "score": 0
              },
              "identification_details": {
                "has_exclusions": false,
                "score": 0
              },
              "industry_sector": {
                "has_exclusions": false,
                "score": 0
              },
              "year_of_birth": {
                "has_exclusions": true,
                "score": 0
              },
              "deceased": {
                "has_exclusions": false,
                "score": 0
              }
            }
          },
          "type": "risk-entity-screening-cases"
        }
      }
    end

    def association_url
      make_url("risk-entity-screening-associations")
    end

    def association_body(first_name, last_name, birth_year, external_id, nin, country)
      {
        "data": {
          "attributes": {
            "country": country,
            "external_id": external_id,
            "identification_details": {
              "type": "1018", # TAX NUMBER https://developer.dowjones.com/site/docs/risk_and_compliance_apis/risk_and_compliance_2_0/risk_taxonomy_api/index.gsp
              "value": nin,
            },
            "names": [
              {
                "first_name": first_name,
                "last_name": last_name,
                "name_type": "PRIMARY",
              }
            ],
            "record_type": "PERSON",
            "year_of_birth": birth_year,
            "is_deceased": false
          },
          "type": "risk-entity-screening-associations"
        }
      }
    end

    def case_association_url(case_id)
      make_url("risk-entity-screening-cases/#{case_id}/risk-entity-screening-associations")
    end

    def case_association_body(association_id)
      {
        "data": [
          {
            "id": association_id,
            "type": "risk-entity-screening-associations"
          }
        ]
      }
    end

    def matches_url(case_id)
      make_url("risk-entity-screening-cases/#{case_id}/matches")
    end

    def log_decision_url(case_id, match_id)
      make_url("risk-entity-screening-cases/#{case_id}/matches/#{match_id}")
    end

    def log_decision_body(comment, state, risk_rating)
      {
        "data": {
          "attributes": {
            "comment": comment,
            "current_state": state,
            "risk_rating": risk_rating
          },
          "type": "match"
        }
      }
    end

    def config
      Factiva.configuration
    end
  end
end
