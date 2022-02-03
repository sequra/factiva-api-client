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
