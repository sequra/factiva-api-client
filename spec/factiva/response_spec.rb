# frozen_string_literal: true

module Factiva
  RSpec.describe Factiva::Response do
    include Dry::Monads[:result]

    describe ".to_result" do
      subject(:result) { described_class.to_result(HTTP.get(url)) }

      let(:url) { "https://factiva.test/resource" }

      def stub_response(status:, body:)
        WebMock.stub_request(:get, url).to_return(status: status, body: body)
      end

      context "when the response succeeds with a JSON body" do
        before { stub_response(status: 200, body: { "data" => { "id" => "1" } }.to_json) }

        it { is_expected.to eq(Success({ "data" => { "id" => "1" } })) }
      end

      context "when the response succeeds with an empty body" do
        before { stub_response(status: 204, body: "") }

        it { is_expected.to eq(Success({})) }
      end

      context "when the response succeeds with a body that is not JSON" do
        before { stub_response(status: 200, body: "<html>Maintenance</html>") }

        it { is_expected.to eq(Failure({ code: 200, error: "<html>Maintenance</html>" })) }
      end

      context "when the response fails with an error key" do
        before { stub_response(status: 403, body: { "error" => "unauthorized_client" }.to_json) }

        it { is_expected.to eq(Failure({ code: 403, error: "unauthorized_client" })) }
      end

      context "when the response fails with an errors list" do
        let(:errors) { [{ "code" => 1_100_004, "status" => 404, "title" => "The resource was not found" }] }

        before { stub_response(status: 404, body: { "errors" => errors }.to_json) }

        it { is_expected.to eq(Failure({ code: 404, error: errors })) }
      end

      context "when the response fails with a null body" do
        before { stub_response(status: 503, body: nil.to_json) }

        it { is_expected.to eq(Failure({ code: 503, error: nil })) }
      end

      context "when the response fails with an empty body" do
        before { stub_response(status: 503, body: "") }

        it { is_expected.to eq(Failure({ code: 503, error: nil })) }
      end

      context "when the response fails with a body that is not JSON" do
        before { stub_response(status: 502, body: "<html>Bad Gateway</html>") }

        it { is_expected.to eq(Failure({ code: 502, error: "<html>Bad Gateway</html>" })) }
      end
    end
  end
end
