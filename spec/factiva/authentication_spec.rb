# frozen_string_literal: true

require "ostruct"

module Factiva
  RSpec.describe Factiva::Authentication do
    let(:config) { Factiva.configuration(Factiva::REQUEST_API_ACCOUNT) }
    let(:subject) { Authentication.new(config) }

    context "First time authenticating" do
      context "Factiva responds as expected", vcr: { cassette_name: "authentication/first_time_authenticating/ok" } do
        it "returns token" do
          # Two requests: Get authn and Get authz
          expect(subject.client).to receive(:make_request).twice.and_call_original
          expect(subject.token).to eq(
            "eyJhbGciOiJSUzI1NiIsImtpZCI6IjJEN0IwQTFERkJCNzlDRDFBQjM4NzNCMTcyODMyRjkxME"\
            "NEQkRBREIiLCJ0eXAiOiJKV1QifQ.eyJwaWIiOnsiYXBjIjoiUk5DIiwiY3RjIjoiUCIsIm1hc"\
            "3Rlcl9hcHBfaWQiOiJlTnlIckwwQ0xmNEFtRWxnMmZmQjBkcmFmYVVPTndjRyIsInNlcnZpY2V"\
            "fYWNjb3VudF9pZCI6IjlTRVEwMDAyMDAiLCJlbmNyeXB0ZWRfdG9rZW4iOiJJMDBfSlVZVE1OQ"\
            "lRHTTNETU5SU0hBWFc0TUNLSkpMR1NVS0hKWklXWVkyVE5VM0VHV0tHTVI0V1lSMlFLRlJESUs"\
            "zT0tNM1ZHT0pXSUZCSFVTMk9HTk1ET1VSUEpWM1dFVUNLTEJMRU8zMk9QQktHMjNSUUtWWUdTW"\
            "TNDSEZORE0zVEJMQkZIQVpLVEk0WUM2VEJUT000WEFWQlJPWkdWQTVMVE9OQlVPV0wyTEFaRVl"\
            "VU1hKSjJYQzZCUk01QVVLVUo1STQifSwiaXNzIjoiaHR0cHM6Ly9hY2NvdW50cy5kb3dqb25lc"\
            "y5jb20vb2F1dGgyL3YyIiwic3ViIjoiYXV0aDB8NjFiMjcyMGYxYzNiMjI1NmQ3ZTM1Mjc2Iiw"\
            "iYXVkIjoiZU55SHJMMENMZjRBbUVsZzJmZkIwZHJhZmFVT053Y0ciLCJhenAiOiJlTnlIckwwQ"\
            "0xmNEFtRWxnMmZmQjBkcmFmYVVPTndjRyIsImlhdCI6MTY0MzM2OTcyOSwiZXhwIjoxNjQzMzc"\
            "zMzI5fQ.LLUA4Ktx7SDYNwm0ggW7n5vTtnvk6JP_4y5A5Z26J147I6bWFGSxHspSFaplEfNgTK"\
            "AvG5U6ZVPA7EY_dYd9mB8R8TOr7IE0yKJSdgX_wbBg8L7rx6lzAkd0bUTRCsXYU3yvqdGtkPHT"\
            "-iVkPgAUNYiZI8bSEc9lvBVhXPSkT-B_iFoUGuh-JWDZFKHE2OKbxEAmrjUSRqURUGKCLnMx_s"\
            "Hb88TRhiIY9az8mOrXoi-sa7ZAdDkPMUrlJdZQxW9ByfFkVLqRYoGDJBCdqvNTWJ-bzU0jpJXc"\
            "x-EzruhWo9P20jE2IFguueaxQuYruqAgdmiW4ros3Jlw6kaJJGGriw"
          )
        end
      end

      context "retrieve authn token fails", vcr: { cassette_name: "authentication/first_time_authenticating/authn_fails" } do
        it "raises an exception" do
          # One request: Get authn
          expect(subject.client).to receive(:make_request).once.and_call_original
          expect {
            subject.token
          }.to raise_error(RequestError, { code: 403, error: "unauthorized_client" }.to_s)
        end
      end

      context "retrieve authz token fails", vcr: { cassette_name: "authentication/first_time_authenticating/authz_fails" } do
        it "raises an exception" do
          # Two requests: Get authn and Get authz
          expect(subject.client).to receive(:make_request).twice.and_call_original
          expect {
            subject.token
          }.to raise_error(RequestError, { code: 400, error: "request_validation_error" }.to_s)
        end
      end

      context "Factiva connection timed out" do
        before do
          WebMock.stub_request(:post, /oauth2\/v1\/token/).to_timeout
        end

        it "raises Factiva::TimeoutError for CircuitBreaker" do
          expect { subject.token }.to raise_error(Factiva::TimeoutError)
        end
      end
    end

    context "Already authenticated" do
      before do
        # Authenticate first
        VCR.use_cassette("authentication/first_time_authenticating/ok") do
          subject.token
        end
      end

      context "Access token is not expired" do
        it "retrieves token" do
          # Zero requests
          expect(HTTP).not_to receive(:post)
          expect(subject.token).to eq(
            "eyJhbGciOiJSUzI1NiIsImtpZCI6IjJEN0IwQTFERkJCNzlDRDFBQjM4NzNCMTcyODMyRjkxME"\
            "NEQkRBREIiLCJ0eXAiOiJKV1QifQ.eyJwaWIiOnsiYXBjIjoiUk5DIiwiY3RjIjoiUCIsIm1hc"\
            "3Rlcl9hcHBfaWQiOiJlTnlIckwwQ0xmNEFtRWxnMmZmQjBkcmFmYVVPTndjRyIsInNlcnZpY2V"\
            "fYWNjb3VudF9pZCI6IjlTRVEwMDAyMDAiLCJlbmNyeXB0ZWRfdG9rZW4iOiJJMDBfSlVZVE1OQ"\
            "lRHTTNETU5SU0hBWFc0TUNLSkpMR1NVS0hKWklXWVkyVE5VM0VHV0tHTVI0V1lSMlFLRlJESUs"\
            "zT0tNM1ZHT0pXSUZCSFVTMk9HTk1ET1VSUEpWM1dFVUNLTEJMRU8zMk9QQktHMjNSUUtWWUdTW"\
            "TNDSEZORE0zVEJMQkZIQVpLVEk0WUM2VEJUT000WEFWQlJPWkdWQTVMVE9OQlVPV0wyTEFaRVl"\
            "VU1hKSjJYQzZCUk01QVVLVUo1STQifSwiaXNzIjoiaHR0cHM6Ly9hY2NvdW50cy5kb3dqb25lc"\
            "y5jb20vb2F1dGgyL3YyIiwic3ViIjoiYXV0aDB8NjFiMjcyMGYxYzNiMjI1NmQ3ZTM1Mjc2Iiw"\
            "iYXVkIjoiZU55SHJMMENMZjRBbUVsZzJmZkIwZHJhZmFVT053Y0ciLCJhenAiOiJlTnlIckwwQ"\
            "0xmNEFtRWxnMmZmQjBkcmFmYVVPTndjRyIsImlhdCI6MTY0MzM2OTcyOSwiZXhwIjoxNjQzMzc"\
            "zMzI5fQ.LLUA4Ktx7SDYNwm0ggW7n5vTtnvk6JP_4y5A5Z26J147I6bWFGSxHspSFaplEfNgTK"\
            "AvG5U6ZVPA7EY_dYd9mB8R8TOr7IE0yKJSdgX_wbBg8L7rx6lzAkd0bUTRCsXYU3yvqdGtkPHT"\
            "-iVkPgAUNYiZI8bSEc9lvBVhXPSkT-B_iFoUGuh-JWDZFKHE2OKbxEAmrjUSRqURUGKCLnMx_s"\
            "Hb88TRhiIY9az8mOrXoi-sa7ZAdDkPMUrlJdZQxW9ByfFkVLqRYoGDJBCdqvNTWJ-bzU0jpJXc"\
            "x-EzruhWo9P20jE2IFguueaxQuYruqAgdmiW4ros3Jlw6kaJJGGriw"
          )
        end
      end

      context "Access token is expired" do
        before do
          time_now = Time.now.utc
          one_day = 86400
          allow(Time).to receive(:now).and_return(
            OpenStruct.new(utc: time_now + one_day)
          )
        end

        context "Factiva responds as expected", vcr: { cassette_name: "authentication/token_expired/ok" } do
          it "refreshes the token" do
            # One request: Refresh authz
            expect(subject.client).to receive(:make_request).once.and_call_original
            expect(subject.token).to eq(
              "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6Ik4wSTJRekJEUWpRM04wUkJSakJF"\
              "UkRVM05qaEZNREF5T0VWRlJqWkRSVVl4TWtFMU5ERXdSUSJ9.eyJzZXJ2aWNlX2FjY291bnR"\
              "faWQiOiI5U0VRMDAwMjAwIiwiaXNzIjoiaHR0cHM6Ly9hdXRoLmFjY291bnRzLmRvd2pvbmV"\
              "zLmNvbS8iLCJzdWIiOiJhdXRoMHw2MWIyNzIwZjFjM2IyMjU2ZDdlMzUyNzYiLCJhdWQiOiJ"\
              "lTnlIckwwQ0xmNEFtRWxnMmZmQjBkcmFmYVVPTndjRyIsImV4cCI6MTY0MzQxODEwMywiaWF"\
              "0IjoxNjQzMzgyMTAzLCJhenAiOiJlTnlIckwwQ0xmNEFtRWxnMmZmQjBkcmFmYVVPTndjRyJ"\
              "9.ZTpAV_UrlOClNhURjqLoL6f896E3Kh_xsQKuYn9wgd6O6Py2nQdYmp93fFx_FQi2xeOzTS"\
              "VDqP_lHtGgytvQ25pTw_J_I_qkjck40XZLvZ6AZaP6wLZ1kJpr_FyFQCVVFc7MnreAmcpLwP"\
              "rje-AecPJmO65OUdHD-eDvy5fVVs4dbXu9HEQKIb1pzsnDglnRKBUrNVGLjdkabQK5jXQPy9"\
              "fbridZelJiDaC7Qcli_2qXGxzImOS2vymTNhi6svUUOIRnK63Axlk_IT8-iWdVYk6rIKTRZm"\
              "IjnE30wx09RO-slMwY7uaUIW2bY9ilET5A7v7UHxoKQni_zxZsOMvq9Q"
            )
          end
        end

        context "Refresh token request fails", vcr: { cassette_name: "authentication/token_expired/refresh_authz_fails" } do
          it "raises an exception" do
            # One request: Refresh authz
            expect(subject.client).to receive(:make_request).once.and_call_original
            expect {
              subject.token
            }.to raise_error(RequestError, { code: 400, error: "invalid_request" }.to_s)
          end
        end
      end
    end
  end
end
