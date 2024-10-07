require "http"
require "json"

module Factiva
  class Monitoring
    COUNTRY_IDS = {
      "ES" => "SPAIN",
      "FR" => "FRA",
      "IT" => "ITALY",
      "PT" => "PORL",
    }.freeze

    private_class_method :new
    attr_reader :client

    def self.create_case(...)
      instance.create_case(...)
    end

    def self.create_association(...)
      instance.create_association(...)
    end

    def self.add_association_to_case(...)
      instance.add_association_to_case(...)
    end

    def self.get_matches(...)
      instance.get_matches(...)
    end

    def self.log_decision(...)
      instance.log_decision(...)
    end

    def self.reset_auth
      instance.client.set_auth!
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
        @stubbed_create_case = stubbed_create_case
        @stubbed_create_association = stubbed_create_association
        @stubbed_add_association_to_case = stubbed_add_association_to_case
        @stubbed_get_matches = stubbed_get_matches
        @stubbed_log_decision = stubbed_log_decision
      end

      def create_case(...)
        stubbed_create_case
      end

      def create_association(...)
        stubbed_create_association
      end

      def add_association_to_case(...)
        stubbed_add_association_to_case
      end

      def get_matches(...)
        stubbed_get_matches
      end

      def log_decision(...)
        stubbed_log_decision
      end
    end

    def initialize
      @client = Client.new(config)
    end

    def create_case(case_body_payload = nil)
      params = { json: case_body_payload || create_case_body }

      client.make_authorized_request(:post, create_case_url, params)
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

      client.make_authorized_request(:post, association_url, params)
    end

    def add_association_to_case(case_id:, association_id:)
      params = { json: case_association_body(
        association_id,
        )
      }

      client.make_authorized_request(:post, case_association_url(case_id), params)
    end

    def get_matches(case_id:)
      client.make_authorized_request(:get, matches_url(case_id))
    end

    def log_decision(case_id:, match_id:, comment:, state:, risk_rating:)
      params = { json: log_decision_body(
        comment, state, risk_rating,
        )
      }

      client.make_authorized_request(:patch, log_decision_url(case_id, match_id), params)
    end

  private

    def self.instance
      @instance ||= new
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
      Factiva.configuration(Factiva::MONITORING_API_ACCOUNT)
    end
  end
end
