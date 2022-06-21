# frozen_string_literal: true

module Factiva
  RSpec.describe Factiva::Monitoring do
    let(:subject) { Monitoring }

    describe "#create_case", vcr: "monitoring/create_case" do
      it "authenticates and adds a case" do
        response = subject.create_case
        expect(response["data"]["id"]).to eq("2add8f3c-14a2-4115-abde-c3137a5c3149")
      end
    end

    describe "#create_association", vcr: "monitoring/create_association" do
      let(:sample_data) {
        {
          first_name: "Maria Remedios",
          last_name: "Garcia Albert",
          birth_year: 1976,
          external_id: "id1234",
          nin: "00263695-T",
          country_code: "ES",
        }
      }

      it "authenticates and adds an Monitoring" do
        response = subject.create_association(sample_data)
        expect(response["data"]["id"]).to eq("8eece3ab-71e1-47b6-b219-349f278a21b2")
      end
    end

    describe "#add_association_to_case", vcr: "monitoring/add_association_to_case" do
      let(:sample_data) {
        {
          association_id: "8eece3ab-71e1-47b6-b219-349f278a21b2",
          case_id: "2add8f3c-14a2-4115-abde-c3137a5c3149",
        }
      }

      it "authenticates and adds an Association to a Case" do
        response = subject.add_association_to_case(sample_data)

        expect(response["data"]["attributes"]["operation"]).to eq("CORRELATE")
        expect(response["data"]["attributes"]["status"]).to eq("PENDING")
        expect(response["data"]["id"]).to eq("1e3f74a3-776d-41d9-8954-559ce596d27a")
      end
    end

    describe "#get_matches" do
      let(:sample_data) {
        {
          case_id: case_id,
        }
      }

      context "when there isn't matches in the Case", vcr: "monitoring/no_matches" do # this VCR was recorded when there wasn't any match
        let(:case_id) { "06f61bd4-ac2f-492d-85b2-428eacb19d18" }

        it "authenticates and doesn't get matches" do
          response = subject.get_matches(sample_data)
          expect(response["data"].size).to eq(0)
        end
      end

      context "when there are matches in the Case", vcr: "monitoring/matches" do

        let(:case_id) { "2add8f3c-14a2-4115-abde-c3137a5c3149" }

        it "authenticates and doesn't get matches" do
          result = subject.get_matches(sample_data)

          full_expected_result = {
            "peid" => "1003410",
            "type" => "RELATIONSHIP",
            "variation" => {"structural"=>false, "linguistic"=>false, "non_linguistic"=>false},
            "title" => "OFAC - Principal Significant Foreign Narcotics Trafficker List",
            "match_id" => "5a9f0745fc8f0090fbe7a4ffedefc62e71e46d3355aacb82b801c28ea8f0637a",
            "match_name" => "Maria Remedios Garcia Albert",
            "match_type" => "PRECISE",
            "percentage_match" => 1.0,
            "subscription_name" => "Maria Remedios Garcia Albert",
            "boosting_events" => [],
            "icon_hints" => ["SAN-PERSON", "SI-PERSON"],
            "primary_country" => "SPAIN",
            "is_score_boosted" => false,
            "current_state" => {"timestamp" => "2022-06-21T10:01:22", "state" => "OPEN"},
            "birthdates" => [{"day"=>17, "year"=>1951, "month"=>2}],
            "gender" => "FEMALE",
            "is_deceased" => false,
            "match_date" => "2022-06-21T10:01:22",
            "primary_name" => {"name_type" => "PRIMARY", "first_name" => "Maria Remedios", "last_name" => "Garcia Albert"},
            "has_alerts" => true,
            "is_match_valid" => true,
          }.freeze

          expect(result["data"][0]["attributes"]["matches"][0]).to eq(full_expected_result)
          expect(result["data"][0]["attributes"]["matches"][0]["subscription_name"]).to eq("Maria Remedios Garcia Albert")
          expect(result["data"][0]["attributes"]["matches"][0]["match_id"]).to eq("5a9f0745fc8f0090fbe7a4ffedefc62e71e46d3355aacb82b801c28ea8f0637a")
          expect(result["data"][0]["attributes"]["external_id"]).to eq("id1234")
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
        res = subject.log_decision(sample_data)

        expect(res["data"]["attributes"]["current_state"]).to eq({"timestamp"=>"2022-06-21T10:04:37.645", "comment"=>"False positive", "state"=>"CLEARED", "risk_rating"=>1})
      end
    end
  end
end
