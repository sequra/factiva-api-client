# frozen_string_literal: true

module Factiva
  RSpec.describe Factiva::Request do
    let(:subject) { Request }
    let(:params) { { first_name: "Jhon", last_name: "Smith" } }

    context "#Search" do
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
          allow(HTTP).to receive(:post).and_raise(SocketError)
        end

        it "raises an exception" do
          expect {
            subject.search(params)
          }.to raise_error(RequestError, "Failed to connect to Factiva")
        end
      end
    end
  end
end
