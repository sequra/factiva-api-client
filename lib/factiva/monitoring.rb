require "http"
require "json"
require "dry/monads"

module Factiva
  class Monitoring
    include Dry::Monads[:result]

    COUNTRY_IDS = {
      "ES" => "SPAIN",
      "FR" => "FRA",
      "IT" => "ITALY",
      "PT" => "PORL",
    }.freeze

    DEFAULT_CONTENT_TYPE = "application/json".freeze
    BULK_MATCH_UPDATE_CONTENT_TYPE = "application/vnd.dowjones.dna.bulk-match-update.v_1.2+json".freeze

    private_class_method :new
    attr_reader :auth

    def self.create_case(**args)
      instance.create_case(**args)
    end

    def self.create_association(**args)
      instance.create_association(**args)
    end

    def self.bulk_create_associations(**args)
      instance.bulk_create_associations(**args)
    end

    def self.update_association(**args)
      instance.update_association(**args)
    end

    def self.delete_association(**args)
      instance.delete_association(**args)
    end

    def self.add_association_to_case(**args)
      instance.add_association_to_case(**args)
    end

    def self.remove_association_from_case(**args)
      instance.remove_association_from_case(**args)
    end

    def self.get_profile(**args)
      instance.get_profile(**args)
    end

    def self.get_matches(**args)
      instance.get_matches(**args)
    end

    def self.log_decision(**args)
      instance.log_decision(**args)
    end

    def self.update_matches(**args)
      instance.update_matches(**args)
    end

    def self.reset_auth
      instance.set_auth
    end

    def self.stub!(create_case: {},
        create_association: {},
        bulk_create_associations: {},
        update_association: {},
        delete_association: {},
        add_association_to_case: {},
        remove_association_from_case: {},
        get_profile: {},
        get_matches: {},
        log_decision: {},
        update_matches: {}
      )
      @instance = MockedRequest.new(
        create_case,
        create_association,
        bulk_create_associations,
        update_association,
        delete_association,
        add_association_to_case,
        remove_association_from_case,
        get_profile,
        get_matches,
        log_decision,
        update_matches
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
      :stubbed_update_association,
      :stubbed_delete_association,
      :stubbed_add_association_to_case,
      :stubbed_remove_association_from_case,
      :stubbed_get_profile,
      :stubbed_get_matches,
      :stubbed_log_decision,
      :stubbed_update_matches

      def initialize(stubbed_create_case,
        stubbed_create_association,
        stubbed_update_association,
        stubbed_delete_association,
        stubbed_add_association_to_case,
        stubbed_remove_association_from_case,
        stubbed_get_profile,
        stubbed_get_matches,
        stubbed_log_decision,
        stubbed_update_matches
      )
        @stubbed_create_case = stubbed_create_case
        @stubbed_create_association = stubbed_create_association
        @stubbed_update_association = stubbed_update_association
        @stubbed_delete_association = stubbed_delete_association
        @stubbed_add_association_to_case = stubbed_add_association_to_case
        @stubbed_remove_association_from_case = stubbed_remove_association_from_case
        @stubbed_get_profile = stubbed_get_profile
        @stubbed_get_matches = stubbed_get_matches
        @stubbed_log_decision = stubbed_log_decision
        @stubbed_update_matches = stubbed_update_matches
      end

      def create_case(**args)
        stubbed_create_case
      end

      def create_association(**args)
        stubbed_create_association
      end

      def bulk_create_associations(**args)
        stubbed_bulk_create_associations
      end

      def update_association(**args)
        stubbed_update_association
      end

      def delete_association(**args)
        stubbed_delete_association
      end

      def add_association_to_case(**args)
        stubbed_add_association_to_case
      end

      def remove_association_from_case(**args)
        subbed_remove_association_from_case
      end

      def get_profile(**args)
        stubbed_get_profile
      end

      def get_matches(**args)
        stubbed_get_matches
      end

      def log_decision(**args)
        stubbed_log_decision
      end

      def update_matches(**args)
        stubbed_update_matches
      end
    end

    def initialize
      set_auth
    end

    def create_case(case_body_payload = nil)
      params = { json: case_body_payload || create_case_body }

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
      post(associations_url, params)
        .or       { set_auth; post(associations_url, params) }
        .value_or { |error| raise RequestError.new(error) }
    end

    def bulk_create_associations(case_id:, associations:)
      params = { json: { data: { attributes: {
        associations: associations.map { normalize_country(_1) }
      }, type: "risk-entity-screening-associations" } } }

      post(bulk_create_associations_url(case_id), params)
        .or       { set_auth; post(bulk_create_associations_url(case_id), params) }
        .value_or { |error| raise RequestError.new(error) }
    end

    def update_association(association_id:, params:)
      params = { json: association_body(
        params.fetch(:first_name),
        params.fetch(:last_name),
        params.fetch(:birth_year),
        params.fetch(:external_id),
        params.fetch(:nin),
        COUNTRY_IDS.fetch(params.fetch(:country_code)),
      ) }

      url = association_url(association_id)

      # If the request fails auth is reset and the request retried
      patch(url, params)
        .or       { set_auth; patch(url, params) }
        .value_or { |error| raise RequestError.new(error) }
    end

    def delete_association(association_id:)
      url = association_url(association_id)

      # If the request fails auth is reset and the request retried
      delete(url)
        .or       { set_auth; delete(url) }
        .value_or { |error| raise RequestError.new(error) }
    end

    def add_association_to_case(case_id:, association_id:)
      params = { json: case_association_body(
        association_id,
        )
      }

      # If the request fails auth is reset and the request retried
      post(case_associations_url(case_id), params)
        .or       { set_auth; post(case_associations_url(case_id), params) }
        .value_or { |error| raise RequestError.new(error) }
    end

    def remove_association_from_case(case_id:, association_id:)
      url = case_association_url(case_id, association_id)

      # If the request fails auth is reset and the request retried
      delete(url)
        .or       { set_auth; delete(url) }
        .value_or { |error| raise RequestError.new(error) }
    end

    def get_matches(case_id:, offset: 0, limit: 100, has_alerts: "any", is_match_valid: "any")
      url = matches_url(
        case_id,
        offset: offset,
        limit: limit,
        has_alerts: has_alerts,
        is_match_valid: is_match_valid
      )

      # If the request fails auth is reset and the request retried
      get(url)
        .or       { set_auth; get(url) }
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

    def update_matches(case_id:, matches_data:)
      params = { json: matches_bulk_body(matches_data) }
      url = bulk_match_update_url(case_id)
      headers = {
        accept: BULK_MATCH_UPDATE_CONTENT_TYPE,
        content_type: BULK_MATCH_UPDATE_CONTENT_TYPE,
      }

      # If the request fails auth is reset and the request retried
      patch(url, params, headers)
        .or       { set_auth; patch(url, params, headers) }
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

    def delete(url)
      make_request(:delete, url)
    end

    def patch(url, params, headers = {})
      make_request(:patch, url, params, headers)
    end

    def get(url)
      make_request(:get, url)
    end

    def make_request(http_method, url, params = nil, headers = {})
      http_params = [http_method, url, params].compact

      begin
        response = HTTP
          .headers(accept: headers.fetch(:accept, DEFAULT_CONTENT_TYPE))
          .headers("Content-Type" => headers.fetch(:content_type, DEFAULT_CONTENT_TYPE))
          .timeout(config.timeout)
          .auth("Bearer #{auth.token}")
          .send(*http_params)

        response_body = response.body.to_s.empty? ? {} : JSON.parse(response.body.to_s)

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

    def associations_url
      make_url("risk-entity-screening-associations")
    end

    def association_url(association_id)
      make_url("risk-entity-screening-associations/#{association_id}")
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

    def case_associations_url(case_id)
      make_url("risk-entity-screening-cases/#{case_id}/risk-entity-screening-associations")
    end

    def case_association_url(case_id, association_id)
      make_url("risk-entity-screening-cases/#{case_id}/risk-entity-screening-associations/#{association_id}")
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

    def profile_url(profile_id)
      make_url("riskentities/profiles/#{profile_id}")
    end

    def matches_url(case_id, offset:, limit:, has_alerts:, is_match_valid:)
      make_url(
        "risk-entity-screening-cases/#{case_id}/matches?" \
        "page[offset]=#{offset}&page[limit]=#{limit}&" \
        "filter[has_alerts]=#{has_alerts}&filter[is_match_valid]=#{is_match_valid}"
      )
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

    def matches_bulk_body(matches_data)
      data = matches_data.map do |match|
        {
          "id": match.fetch(:match_id),
          "type": "matches",
          "attributes": {
            "risk_rating": match.fetch(:risk_rating, nil), # optional
            "current_state": match.fetch(:state),
            "comment": match.fetch(:comment, nil), # optional
          }
        }
      end

      { "data": data }
    end

    def bulk_match_update_url(case_id)
      make_url("risk-entity-screening-cases/#{case_id}/bulk-match-update")
    end

    def bulk_create_associations_url(case_id)
      make_url("risk-entity-screening-cases/#{case_id}/bulk-associations")
    end

    def normalize_country(association)
      country = association[:country]
      return association unless country.is_a?(String)

      association.merge(country: COUNTRY_IDS.fetch(country))
    end

    def config
      Factiva.configuration(Factiva::MONITORING_API_ACCOUNT)
    end
  end
end
