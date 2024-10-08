# frozen_string_literal: true

module Factiva
  RSpec.describe Factiva::Monitoring do
    let(:subject) { Monitoring }

    describe "#create_case", vcr: "monitoring/create_case" do
      it "authenticates and adds a case" do
        response = subject.create_case
        expect(response["data"]["id"]).to eq("296373b3-80ee-4fb7-9f2e-b43604051c0b")
      end
    end

    describe "#create_association" do
      context "with correct year", vcr: "monitoring/create_association" do
        let(:sample_data) {
          {
            first_name: "Maria Remedios",
            last_name: "Garcia Albert",
            birth_year: 1951, # valid year
            external_id: "id1234",
            nin: "00263695-T",
            country_code: "ES",
          }
        }

        it "authenticates and adds an Monitoring" do
          response = subject.create_association(**sample_data)
          expect(response["data"]["id"]).to eq("bb7a6844-7faf-44ef-91fe-eabeb7bbe640")
        end
      end

      context "with incorrect year", vcr: "monitoring/create_association_2" do
        let(:sample_data) {
          {
            first_name: "Maria Remedios",
            last_name: "Garcia Albert",
            birth_year: 1976, # invalid year
            external_id: "id-XXXXXXX",
            nin: "00263695-T",
            country_code: "ES",
          }
        }

        it "authenticates and adds an Monitoring" do
          response = subject.create_association(**sample_data)
          expect(response["data"]["id"]).to eq("3acf8384-dfcd-46d4-9a22-6eb4077889d0")
        end
      end
    end

    describe "#add_association_to_case", vcr: "monitoring/add_association_to_case" do
      let(:sample_data1) {
        {
          association_id: "bb7a6844-7faf-44ef-91fe-eabeb7bbe640",
          case_id: "296373b3-80ee-4fb7-9f2e-b43604051c0b",
        }
      }

      let(:sample_data2) {
        {
          association_id: "3acf8384-dfcd-46d4-9a22-6eb4077889d0",
          case_id: "296373b3-80ee-4fb7-9f2e-b43604051c0b",
        }
      }

      it "authenticates and adds two Associations to a Case" do
        response = subject.add_association_to_case(**sample_data1)

        expect(response["data"]["attributes"]["operation"]).to eq("CORRELATE")
        expect(response["data"]["attributes"]["status"]).to eq("PENDING")
        expect(response["data"]["id"]).to eq("0b253253-4893-40a0-848b-ca3abdab39b0")

        response = subject.add_association_to_case(**sample_data2)

        expect(response["data"]["attributes"]["operation"]).to eq("CORRELATE")
        expect(response["data"]["attributes"]["status"]).to eq("PENDING")
        expect(response["data"]["id"]).to eq("7c0b2831-e042-4e6e-8d35-5da172c0a860")
      end
    end

    describe "#get_matches" do
      let(:sample_data) {
        {
          case_id: case_id,
        }
      }

      context "when there isn't matches in the Case", vcr: "monitoring/no_matches" do # this VCR was recorded when there wasn't any match
        let(:case_id) { "91473caa-9eb8-4eb1-891d-bde3d7c80cdd" }

        it "authenticates and doesn't get matches" do
          response = subject.get_matches(**sample_data)
          expect(response["data"].size).to eq(0)
        end
      end

      context "when there are matches in the Case", vcr: "monitoring/matches" do

        let(:case_id) { "296373b3-80ee-4fb7-9f2e-b43604051c0b" }

        it "authenticates and returns 2 matches: 1 valid and 1 invalid" do
          result = subject.get_matches(**sample_data)
          expect(result["data"].size).to eq(2)

          invalid_match = {
            "peid" => "1003410",
            "type" => "RELATIONSHIP",
            "variation" => {"structural" => false, "linguistic" => false, "non_linguistic" => false},
            "title" => "OFAC - Principal Significant Foreign Narcotics Trafficker List",
            "match_id" => "239b4a188aff307a328984b0129dbb3a1fd5a9e9385e664fb3091fcce67ecd17",
            "match_name" => "Maria Remedios Garcia Albert",
            "match_type" => "PRECISE",
            "percentage_match" =>1.0,
            "subscription_name" => "Maria Remedios Garcia Albert",
            "boosting_events" =>[],
            "icon_hints" => ["SAN-PERSON", "SI-PERSON"],
            "primary_country" => "SPAIN",
            "is_score_boosted" => false,
            "current_state" => {"timestamp" => "2022-06-22T07:41:53", "state" => "OPEN"},
            "birthdates" => [{"day" => 17, "year" => 1951, "month" => 2}],
            "gender" => "FEMALE",
            "is_deceased" => false,
            "match_date" => "2022-06-22T07:41:53",
            "primary_name" => {"name_type" => "PRIMARY", "first_name" => "Maria Remedios", "last_name" => "Garcia Albert"},
            "has_alerts" => false,
            "is_match_valid" => false,
            "match_invalid_date" => "2022-06-22T07:41:53.349",
            "match_invalid_reason" => "Match excluded by filter: year_of_birth"
          }.freeze

          valid_match = {
            "peid" => "1003410",
            "type" => "RELATIONSHIP",
            "variation" => {"structural"=>false, "linguistic"=>false, "non_linguistic"=>false},
            "title" => "OFAC - Principal Significant Foreign Narcotics Trafficker List",
            "match_id" => "5e7a91388deea1e1368937aaa00c69635890f51e964909eb1f4daccf2ee69ca5",
            "match_name" => "Maria Remedios Garcia Albert",
            "match_type" => "PRECISE",
            "percentage_match" => 1.0,
            "subscription_name" => "Maria Remedios Garcia Albert",
            "boosting_events" => [],
            "icon_hints" => ["SAN-PERSON", "SI-PERSON"],
            "primary_country" => "SPAIN",
            "is_score_boosted" => false,
            "current_state" => {"timestamp" => "2022-06-22T07:41:54", "state" => "OPEN"},
            "birthdates" => [{"day"=>17, "year"=>1951, "month"=>2}],
            "gender" => "FEMALE",
            "is_deceased" => false,
            "match_date" => "2022-06-22T07:41:54",
            "primary_name" => {"name_type" => "PRIMARY", "first_name" => "Maria Remedios", "last_name" => "Garcia Albert"},
            "has_alerts" => true,
            "is_match_valid" => true,
          }.freeze

          expect(result["data"][0]["attributes"]["external_id"]).to eq("id-XXXXXXX")
          expect(result["data"][0]["attributes"]["matches"][0]["subscription_name"]).to eq("Maria Remedios Garcia Albert")
          expect(result["data"][0]["attributes"]["matches"][0]["is_match_valid"]).to be_falsey
          expect(result["data"][0]["attributes"]["matches"][0]["match_invalid_reason"]).to eq "Match excluded by filter: year_of_birth"
          expect(result["data"][0]["attributes"]["matches"][0]).to eq(invalid_match)

          expect(result["data"][1]["attributes"]["external_id"]).to eq("id1234")
          expect(result["data"][1]["attributes"]["matches"][0]["subscription_name"]).to eq("Maria Remedios Garcia Albert")
          expect(result["data"][1]["attributes"]["matches"][0]["is_match_valid"]).to be_truthy
          expect(result["data"][1]["attributes"]["matches"][0]).to eq(valid_match)
        end
      end

      context "Factiva connection timed out", vcr: "monitoring/authentication_only" do
        before do
          WebMock.stub_request(:get, /risk-entity-screening-cases/).to_timeout
        end

        it "raises Factiva::TimeoutError for CircuitBreaker" do
          expect {
            subject.get_matches({ case_id: "id" })
          }.to raise_error(Factiva::TimeoutError)
        end
      end
    end

    describe "#log_decision", vcr: "monitoring/log_decision" do
      let(:sample_data) {
        {
          match_id: "5a9f0745fc8f0090fbe7a4ffedefc62e71e46d3355aacb82b801c28ea8f0637a",
          case_id: "2add8f3c-14a2-4115-abde-c3137a5c3149",
          comment: "False positive",
          state: "CLEARED",
          risk_rating: 1,
        }
      }

      it "authenticates and Logs a decision to a Match" do
        res = subject.log_decision(**sample_data)

        expect(res["data"]["attributes"]["current_state"]).to eq({"timestamp"=>"2022-06-21T10:04:37.645", "comment"=>"False positive", "state"=>"CLEARED", "risk_rating"=>1})
      end
    end
  end
end
