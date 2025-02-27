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

    describe "#bulk_create_associations" do
      context "with correct data", vcr: "monitoring/bulk_create_associations" do
        let(:associations) { [{
          country: "ES",
          external_id: "MerchantEntity#123",
          identification_details: {
            "type": "1018", # 1018 is for Tax number
            "value": "foobar"
          },
          industry_sector: "iecom", # https://developer.dowjones.com/documents/site-docs-getting_started-data_selection_samples-financial_technology
          names: [{ entity_name: "Foo", name_type: "PRIMARY" }],
          record_type: "ENTITY",
        }] }

        it "authenticates and creates the associations" do
          response = subject.bulk_create_associations(
            case_id: "296373b3-80ee-4fb7-9f2e-b43604051c0b",
            associations: associations
          )
          expect(response["data"]["attributes"]).to include(
            "case_id" => "296373b3-80ee-4fb7-9f2e-b43604051c0b",
            "operation" => "BULK",
            "status" => "PROCESSING",
            "invalid_associations" => 0,
            "processing_associations" => 1,
          )
        end
      end
    end

    describe "#update_association" do
      context "with correct year", vcr: "monitoring/update_association" do
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

        it "authenticates and updates the association" do
          response = subject.update_association(
            association_id: "bb7a6844-7faf-44ef-91fe-eabeb7bbe640",
            params: sample_data
          )
          expect(response["data"]["id"]).to eq("bb7a6844-7faf-44ef-91fe-eabeb7bbe640")
        end
      end
    end

    describe "#delete_association" do
      context "when the association can be removed", vcr: "monitoring/delete_association" do
        it "authenticates and delete the association" do
          response = subject.delete_association(association_id: "10d89388-60a0-41c2-8497-74f4ed4ad4e5")
          expect(response).to eq({})
        end
      end

      context "when factiva returns an error", vcr: "monitoring/delete_association_invalid" do
        it "raises a Factiva::RequestError" do
          expect {
            subject.delete_association(association_id: "invalid_id")
          }.to raise_error(Factiva::RequestError)
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

    describe "#remove_association_from_case" do
      context "with correct year", vcr: "monitoring/remove_association_from_case" do
        it "authenticates and removes association from the case" do
          response = subject.remove_association_from_case(
            case_id: "296373b3-80ee-4fb7-9f2e-b43604051c0b",
            association_id: "3acf8384-dfcd-46d4-9a22-6eb4077889d0",
          )
          expect(response["data"]["attributes"]["operation"]).to eq("DECORRELATE")
          expect(response["data"]["attributes"]["status"]).to eq("COMPLETED")
          expect(response["data"]["attributes"]["case_id"]).to eq("296373b3-80ee-4fb7-9f2e-b43604051c0b")
          expect(response["data"]["id"]).to eq("85fb5701-4832-4647-b506-cd07c36aabc6")
        end
      end
    end

    describe "#get_matches" do
      let(:sample_data) {
        {
          case_id: case_id,
        }
      }

      # this VCR was recorded when there wasn't any match
      context "when there isn't matches in the Case", vcr: "monitoring/no_matches" do
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
            "variation" => { "structural" => false, "linguistic" => false, "non_linguistic" => false },
            "title" => "OFAC - Principal Significant Foreign Narcotics Trafficker List",
            "match_id" => "239b4a188aff307a328984b0129dbb3a1fd5a9e9385e664fb3091fcce67ecd17",
            "match_name" => "Maria Remedios Garcia Albert",
            "match_type" => "PRECISE",
            "percentage_match" => 1.0,
            "subscription_name" => "Maria Remedios Garcia Albert",
            "boosting_events" => [],
            "icon_hints" => ["SAN-PERSON", "SI-PERSON"],
            "primary_country" => "SPAIN",
            "is_score_boosted" => false,
            "current_state" => { "timestamp" => "2022-06-22T07:41:53", "state" => "OPEN" },
            "birthdates" => [{ "day" => 17, "year" => 1951, "month" => 2 }],
            "gender" => "FEMALE",
            "is_deceased" => false,
            "match_date" => "2022-06-22T07:41:53",
            "primary_name" => { "name_type" => "PRIMARY", "first_name" => "Maria Remedios", "last_name" => "Garcia Albert" },
            "has_alerts" => false,
            "is_match_valid" => false,
            "match_invalid_date" => "2022-06-22T07:41:53.349",
            "match_invalid_reason" => "Match excluded by filter: year_of_birth"
          }.freeze

          valid_match = {
            "peid" => "1003410",
            "type" => "RELATIONSHIP",
            "variation" => { "structural" => false, "linguistic" => false, "non_linguistic" => false },
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
            "current_state" => { "timestamp" => "2022-06-22T07:41:54", "state" => "OPEN" },
            "birthdates" => [{ "day" => 17, "year" => 1951, "month" => 2 }],
            "gender" => "FEMALE",
            "is_deceased" => false,
            "match_date" => "2022-06-22T07:41:54",
            "primary_name" => { "name_type" => "PRIMARY", "first_name" => "Maria Remedios", "last_name" => "Garcia Albert" },
            "has_alerts" => true,
            "is_match_valid" => true,
          }.freeze

          expect(result["data"][0]["attributes"]["external_id"]).to eq("id-XXXXXXX")
          expect(result["data"][0]["attributes"]["matches"][0]["subscription_name"]).to eq("Maria Remedios Garcia Albert")
          expect(result["data"][0]["attributes"]["matches"][0]["is_match_valid"]).to be_falsey
          expect(result["data"][0]["attributes"]["matches"][0]["match_invalid_reason"])
            .to eq "Match excluded by filter: year_of_birth"
          expect(result["data"][0]["attributes"]["matches"][0]).to eq(invalid_match)

          expect(result["data"][1]["attributes"]["external_id"]).to eq("id1234")
          expect(result["data"][1]["attributes"]["matches"][0]["subscription_name"]).to eq("Maria Remedios Garcia Albert")
          expect(result["data"][1]["attributes"]["matches"][0]["is_match_valid"]).to be_truthy
          expect(result["data"][1]["attributes"]["matches"][0]).to eq(valid_match)
        end

        context "when filtering by valid matches", vcr: "monitoring/matches_has_alerts" do
          # at the moment of recording this VCR, there are 2 matches with alerts
          let(:match_attributes) { result["data"].first["attributes"]["matches"] }
          let(:result) { subject.get_matches(**sample_data, has_alerts: true, is_match_valid: true) }

          it "authenticates and returns matches with alerts" do
            result

            expect(result["data"].size).to eq(2)
            expect(match_attributes.first["has_alerts"]).to be_truthy
            expect(match_attributes.first["is_match_valid"]).to be_truthy
            expect(match_attributes.last["has_alerts"]).to be_truthy
            expect(match_attributes.last["is_match_valid"]).to be_truthy
          end
        end
      end

      context "Factiva connection timed out", vcr: "monitoring/authentication_only" do
        before do
          WebMock.stub_request(:get, /risk-entity-screening-cases/).to_timeout
        end

        it "raises Factiva::TimeoutError for CircuitBreaker" do
          expect {
            subject.get_matches(case_id: "id")
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

        expect(res["data"]["attributes"]["current_state"]).to eq({ "timestamp" => "2022-06-21T10:04:37.645",
"comment" => "False positive", "state" => "CLEARED", "risk_rating" => 1 })
      end
    end

    describe "#update_matches" do
      let(:response) { subject.update_matches(case_id: case_id, matches_data: matches_data) }
      let(:case_id) { "296373b3-80ee-4fb7-9f2e-b43604051c0b" }

      context "when matches can be updated", vcr: "monitoring/update_matches" do
        let(:matches_data) { [
          {
            match_id: "f9cbfd58dd31f572e979392b3023b2e9ff660023d9ff1e381c4a525c75036daa",
            comment: "False positive",
            state: "CLEARED",
            risk_rating: 1,
          },
          {
            match_id: "16bbd1ae6466bbcb1868ce2f5bda3fede446ac2764146be2dcdc144433928150",
            comment: "Not the person we were looking for",
            state: "CLEARED",
            risk_rating: 1,
          }
        ] }

        it "authenticates and updates the matches", :aggregate_failures do
          expect(response["data"].size).to eq(2)
          expect(response["data"].first["attributes"]["current_state"]).to eq(
            "timestamp" => "2025-02-06T11:19:24.528273",
            "comment" => "Not the person we were looking for",
            "state" => "CLEARED",
            "risk_rating" => 1
          )
          expect(response["data"].last["attributes"]["current_state"]).to eq(
            "timestamp" => "2025-02-06T11:19:24.528275",
            "comment" => "False positive",
            "state" => "CLEARED",
            "risk_rating" => 1
          )
        end
      end

      context "when matches can't be updated", vcr: "monitoring/update_matches_invalid" do
        let(:matches_data) { [
          {
            match_id: "invalid",
            comment: "False positive",
            state: "CLEARED",
            risk_rating: 1,
          },
          {
            match_id: "16bbd1ae6466bbcb1868ce2f5bda3fede446ac2764146be2dcdc144433928150",
            comment: "False positive",
            state: "CLEARD",
            risk_rating: 1,
          }
        ] }

        it "raises a Factiva::RequestError" do
          expect {
            response
          }.to raise_error(Factiva::RequestError)
        end
      end
    end
  end
end
