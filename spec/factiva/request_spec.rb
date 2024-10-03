# frozen_string_literal: true

module Factiva
  RSpec.describe Factiva::Request do
    let(:subject) { Request }

    context "#Search" do
      let(:params) { { first_name: "John", last_name: "Smith" } }

      context "First search", vcr: "search/first_search" do
        it "authenticates and returns search info" do
          response = subject.search(**params)
          expect(response["meta"]["total_count"]).to eq(93)
          expect(response["data"][0]["type"]).to eq("RiskEntities")
        end
      end

      context "Second search" do
        before do
          VCR.use_cassette("search/first_search") do
            subject.search(**params)
          end
        end

        it "returns search info", vcr: "search/second_search" do
          response = subject.search(**params)
          expect(response["meta"]["total_count"]).to eq(93)
          expect(response["data"][0]["type"]).to eq("RiskEntities")
        end

        context "filtering by date" do
          context "using year, month and day option", vcr: "search/filter_by_date" do
            let(:params) do
              {
                first_name: "John",
                last_name: "Smith",
                birth_year: "1992",
                birth_month: "12",
                birth_day: "22"
              }
            end

            it "returns search info" do
              response = subject.search(**params)
              expect(response["meta"]["total_count"]).to eq(42)
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
              response = subject.search(**params)
              expect(response["meta"]["total_count"]).to eq(42)
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
              response = subject.search(**params)
              expect(response["meta"]["total_count"]).to eq(42)
              expect(response["data"][0]["type"]).to eq("RiskEntities")
            end
          end
        end

        context "with limits and offset" do
          let(:params) do
            {
              first_name: "John",
              last_name: "Smith",
              limit: 50,
              offset: 20
            }
          end
          it "returns search info", vcr: "search/limit_and_offset" do
            response = subject.search(**params)
            expect(response["meta"]["total_count"]).to eq(93)
            expect(response["meta"]["count"]).to eq(50)
            expect(response["meta"]["next"]).to eq(70)
            expect(response["data"][0]["type"]).to eq("RiskEntities")
          end
        end
      end

      context "Search returns error on the first try", vcr: "search/error_first_try" do
        it "retries the request" do
          response = subject.search(**params)
          expect(response["meta"]["total_count"]).to eq(93)
          expect(response["data"][0]["type"]).to eq("RiskEntities")
        end
      end

      context "Search returns error twice", vcr: "search/error_twice" do
        before do
          allow_any_instance_of(HTTP::Client).to receive(:post).and_raise(SocketError)
        end

        it "raises an exception" do
          expect {
            subject.search(**params)
          }.to raise_error(RequestError, "Failed to connect to Factiva: SocketError")
        end
      end

      context "Factiva connection timed out", vcr: "search/authentication_only" do
        before do
          WebMock.stub_request(:post, /riskentities\/search/).to_timeout
        end

        it "raises HTTP::TimeoutError for CircuitBreaker" do
          expect {
            subject.search(**params)
          }.to raise_error(HTTP::TimeoutError)
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

      context "Factiva connection timed out", vcr: "profile/authentication_only" do
        before do
          WebMock.stub_request(:get, /riskentities\/profiles/).to_timeout
        end

        it "raises HTTP::TimeoutError for CircuitBreaker" do
          expect {
            subject.profile(profile_id)
          }.to raise_error(HTTP::TimeoutError)
        end
      end
    end

    context "#Stub!" do
      let(:search_params) { { first_name: "Jhon", last_name: "Smith" } }
      let(:profile_id)    { "2261549" }

      context "stubbing the request" do
        let(:stubbed_search) do
          {
            "meta" => "stubbed",
            "data" => [
              "name" => "Jhon Search Stubbed",
              "last_name" => "Smith Search Stubbed"
            ]
          }
        end

        let(:stubbed_profile) do
          {
            "data" => {
              "name" => "Jhon Profile Stubbed",
              "last_name" => "Smith Profile Stubbed"
            }
          }
        end

        before do
          subject.stub!(search: stubbed_search, profile: stubbed_profile)
        end

        it "returns stubbed response" do
          expect(subject.search(**search_params)).to eq(stubbed_search)
          expect(subject.profile(profile_id)).to eq(stubbed_profile)
        end

        context "unstubbing the request after stubbing" do
          before do
            subject.unstub!
          end

          it "makes real search request", vcr: "search/first_search" do
            search_response = subject.search(**search_params)
            expect(search_response["meta"]["total_count"]).to eq(93)
            expect(search_response["data"][0]["type"]).to eq("RiskEntities")
          end

          it "makes real profile request", vcr: "profile/first_profile" do
            profile_response = subject.profile(profile_id)
            expect(profile_response["data"]["id"]).to eq(profile_id)
            expect(profile_response["data"]["type"]).to eq("profiles")
          end
        end
      end
    end
  end
end
