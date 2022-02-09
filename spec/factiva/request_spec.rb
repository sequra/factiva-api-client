# frozen_string_literal: true

module Factiva
  RSpec.describe Factiva::Request do
    let(:subject) { Request }

    context "#Search" do
      let(:params) { { first_name: "Jhon", last_name: "Smith" } }

      context "First search", vcr: "search/first_search" do
        it "authenticates and returns search info" do
          response = subject.search(params)
          expect(response["meta"]["total_count"]).to eq(99)
          expect(response["data"][0]["type"]).to eq("RiskEntities")
        end
      end

      context "Second search" do
        before do
          VCR.use_cassette("search/first_search") do
            subject.search(params)
          end
        end

        it "returns search info", vcr: "search/second_search" do
          response = subject.search(params)
          expect(response["meta"]["total_count"]).to eq(99)
          expect(response["data"][0]["type"]).to eq("RiskEntities")
        end

        context "filtering by date" do
          context "using year, month and day option", vcr: "search/filter_by_date" do
            let(:params) do
              {
                first_name: "Jhon",
                last_name: "Smith",
                birth_year: "1992",
                birth_month: "12",
                birth_day: "22"
              }
            end

            it "returns search info" do
              response = subject.search(params)
              expect(response["meta"]["total_count"]).to eq(47)
              expect(response["data"][0]["type"]).to eq("RiskEntities")
            end
          end

          context "using birthdate option", vcr: "search/filter_by_date" do
            let(:params) do
              {
                first_name: "Jhon",
                last_name: "Smith",
                birth_date: Date.new(1992, 12, 22)
              }
            end

            it "returns search info" do
              response = subject.search(params)
              expect(response["meta"]["total_count"]).to eq(47)
              expect(response["data"][0]["type"]).to eq("RiskEntities")
            end
          end

          context "using both options", vcr: "search/filter_by_date" do
            let(:params) do
              {
                first_name: "Jhon",
                last_name: "Smith",
                birth_date: Date.new(1992, 12, 22),
                birth_year: "1980",
                birth_month: "5",
                birth_day: "11"
              }
            end
            it "takes birthdate as priority and returns search info" do
              response = subject.search(params)
              expect(response["meta"]["total_count"]).to eq(47)
              expect(response["data"][0]["type"]).to eq("RiskEntities")
            end
          end
        end

        context "with limits and offset" do
          let(:params) do
            {
              first_name: "Jhon",
              last_name: "Smith",
              limit: 50,
              offset: 20
            }
          end
          it "returns search info", vcr: "search/limit_and_offset" do
            response = subject.search(params)
            expect(response["meta"]["total_count"]).to eq(99)
            expect(response["meta"]["count"]).to eq(50)
            expect(response["meta"]["next"]).to eq(70)
            expect(response["data"][0]["type"]).to eq("RiskEntities")
          end
        end
      end

      context "Search returns error on the first try", vcr: "search/error_first_try" do
        it "retries the request" do
          response = subject.search(params)
          expect(response["meta"]["total_count"]).to eq(99)
          expect(response["data"][0]["type"]).to eq("RiskEntities")
        end
      end

      context "Search returns error twice", vcr: "search/error_twice" do
        before do
          allow_any_instance_of(HTTP::Client).to receive(:post).and_raise(SocketError)
        end

        it "raises an exception" do
          expect {
            subject.search(params)
          }.to raise_error(RequestError, "Failed to connect to Factiva: SocketError")
        end
      end
    end

    context "#Profile" do
      let(:profile_id) { "2261549" }

      context "First profile", vcr: "profile/first_profile" do
        it "authenticates and returns profile info" do
          response = subject.profile(profile_id)
          expect(response["data"]["id"]).to eq(profile_id)
          expect(response["data"]["type"]).to eq("profiles")
        end
      end

      context "Second profile request" do
        before do
          VCR.use_cassette("profile/first_profile") do
            subject.profile(profile_id)
          end
        end

        it "returns profile info", vcr: "profile/second_profile" do
          response = subject.profile(profile_id)
          expect(response["data"]["id"]).to eq(profile_id)
          expect(response["data"]["type"]).to eq("profiles")
        end
      end

      context "Profile returns error on the first try", vcr: "profile/error_first_try" do
        it "retries the request" do
          response = subject.profile(profile_id)
          expect(response["data"]["id"]).to eq(profile_id)
          expect(response["data"]["type"]).to eq("profiles")
        end
      end

      context "Profile returns error twice", vcr: "profile/error_twice" do
        before do
          allow_any_instance_of(HTTP::Client).to receive(:get).and_raise(SocketError)
        end

        it "raises an exception" do
          expect {
            subject.profile(profile_id)
          }.to raise_error(RequestError, "Failed to connect to Factiva: SocketError")
        end
      end
    end
  end
end
