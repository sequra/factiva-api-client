# frozen_string_literal: true

module Factiva
  RSpec.describe Factiva::Authentication do
    let(:subject) { Authentication.new }

    context "First time authenticating" do
      context "Factiva responds as expected", vcr: { cassette_name: "first_time_authenticating/ok" } do
        it "returns token" do
          # Two requests: Get authn and Get authz
          expect(HTTP).to receive(:post).twice.and_call_original
          expect(subject.token).to eq(
            "eyJhbGciOiJSUzI1NiIsImtpZCI6IjJEN0IwQTFERkJCNzlDRDFBQjM4NzNCMTcyODMyRjkxMENEQkRBREIiLCJ0eXAiOiJKV1QifQ.eyJwaWIiOnsiYXBjIjoiUk5DIiwiY3RjIjoiUCIsIm1hc3Rlcl9hcHBfaWQiOiJlTnlIckwwQ0xmNEFtRWxnMmZmQjBkcmFmYVVPTndjRyIsInNlcnZpY2VfYWNjb3VudF9pZCI6IjlTRVEwMDAyMDAiLCJlbmNyeXB0ZWRfdG9rZW4iOiJJMDBfSlVZVE1OQlRHTTNETU5SU0hBWFc0TUNLSkpMR1NVS0hKWklXWVkyVE5VM0VHV0tHTVI0V1lSMlFLRlJESUszT0tNM1ZHT0pXSUZCSFVTMk9HTk1ET1VSUEpWM1dFVUNLTEJMRU8zMk9QQktHMjNSUUtWWUdTWTNDSEZORE0zVEJMQkZIQVpLVEk0WUM2VEJUT000WEFWQlJPWkdWQTVMVE9OQlVPV0wyTEFaRVlVU1hKSjJYQzZCUk01QVVLVUo1STQifSwiaXNzIjoiaHR0cHM6Ly9hY2NvdW50cy5kb3dqb25lcy5jb20vb2F1dGgyL3YyIiwic3ViIjoiYXV0aDB8NjFiMjcyMGYxYzNiMjI1NmQ3ZTM1Mjc2IiwiYXVkIjoiZU55SHJMMENMZjRBbUVsZzJmZkIwZHJhZmFVT053Y0ciLCJhenAiOiJlTnlIckwwQ0xmNEFtRWxnMmZmQjBkcmFmYVVPTndjRyIsImlhdCI6MTY0MzM2OTcyOSwiZXhwIjoxNjQzMzczMzI5fQ.LLUA4Ktx7SDYNwm0ggW7n5vTtnvk6JP_4y5A5Z26J147I6bWFGSxHspSFaplEfNgTKAvG5U6ZVPA7EY_dYd9mB8R8TOr7IE0yKJSdgX_wbBg8L7rx6lzAkd0bUTRCsXYU3yvqdGtkPHT-iVkPgAUNYiZI8bSEc9lvBVhXPSkT-B_iFoUGuh-JWDZFKHE2OKbxEAmrjUSRqURUGKCLnMx_sHb88TRhiIY9az8mOrXoi-sa7ZAdDkPMUrlJdZQxW9ByfFkVLqRYoGDJBCdqvNTWJ-bzU0jpJXcx-EzruhWo9P20jE2IFguueaxQuYruqAgdmiW4ros3Jlw6kaJJGGriw"
          )
        end
      end

      context "retrieve authn token fails", vcr: { cassette_name: "first_time_authenticating/authn_fails" } do
        it "raises an exception" do
          # One request: Get authn
          expect(HTTP).to receive(:post).once.and_call_original
          expect{
            subject.token
          }.to raise_error(RequestError, { code: 403, error: "unauthorized_client" }.to_s)
        end
      end

      context "retrieve authz token fails", vcr: { cassette_name: "first_time_authenticating/authz_fails" } do
        it "raises an exception" do
          # Two requests: Get authn and Get authz
          expect(HTTP).to receive(:post).twice.and_call_original
          expect{
            subject.token
          }.to raise_error(RequestError, { code: 400, error: "request_validation_error" }.to_s)
        end
      end
    end

    context "Already authenticated" do
      before do
        # Authenticate first
        VCR.use_cassette("first_time_authenticating/ok") do
          subject.token
        end
      end

      context "Access token is not expired" do
        it "retrieves token" do
          # Zero requests
          expect(HTTP).not_to receive(:post)
          expect(subject.token).to eq(
            "eyJhbGciOiJSUzI1NiIsImtpZCI6IjJEN0IwQTFERkJCNzlDRDFBQjM4NzNCMTcyODMyRjkxMENEQkRBREIiLCJ0eXAiOiJKV1QifQ.eyJwaWIiOnsiYXBjIjoiUk5DIiwiY3RjIjoiUCIsIm1hc3Rlcl9hcHBfaWQiOiJlTnlIckwwQ0xmNEFtRWxnMmZmQjBkcmFmYVVPTndjRyIsInNlcnZpY2VfYWNjb3VudF9pZCI6IjlTRVEwMDAyMDAiLCJlbmNyeXB0ZWRfdG9rZW4iOiJJMDBfSlVZVE1OQlRHTTNETU5SU0hBWFc0TUNLSkpMR1NVS0hKWklXWVkyVE5VM0VHV0tHTVI0V1lSMlFLRlJESUszT0tNM1ZHT0pXSUZCSFVTMk9HTk1ET1VSUEpWM1dFVUNLTEJMRU8zMk9QQktHMjNSUUtWWUdTWTNDSEZORE0zVEJMQkZIQVpLVEk0WUM2VEJUT000WEFWQlJPWkdWQTVMVE9OQlVPV0wyTEFaRVlVU1hKSjJYQzZCUk01QVVLVUo1STQifSwiaXNzIjoiaHR0cHM6Ly9hY2NvdW50cy5kb3dqb25lcy5jb20vb2F1dGgyL3YyIiwic3ViIjoiYXV0aDB8NjFiMjcyMGYxYzNiMjI1NmQ3ZTM1Mjc2IiwiYXVkIjoiZU55SHJMMENMZjRBbUVsZzJmZkIwZHJhZmFVT053Y0ciLCJhenAiOiJlTnlIckwwQ0xmNEFtRWxnMmZmQjBkcmFmYVVPTndjRyIsImlhdCI6MTY0MzM2OTcyOSwiZXhwIjoxNjQzMzczMzI5fQ.LLUA4Ktx7SDYNwm0ggW7n5vTtnvk6JP_4y5A5Z26J147I6bWFGSxHspSFaplEfNgTKAvG5U6ZVPA7EY_dYd9mB8R8TOr7IE0yKJSdgX_wbBg8L7rx6lzAkd0bUTRCsXYU3yvqdGtkPHT-iVkPgAUNYiZI8bSEc9lvBVhXPSkT-B_iFoUGuh-JWDZFKHE2OKbxEAmrjUSRqURUGKCLnMx_sHb88TRhiIY9az8mOrXoi-sa7ZAdDkPMUrlJdZQxW9ByfFkVLqRYoGDJBCdqvNTWJ-bzU0jpJXcx-EzruhWo9P20jE2IFguueaxQuYruqAgdmiW4ros3Jlw6kaJJGGriw"
          )
        end
      end

      context "Access token is expired" do
        before do
          time_now = Time.now
          one_day = 86400
          allow(Time).to receive(:now).and_return(time_now + one_day)
        end

        context "Factiva responds as expected", vcr: { cassette_name: "token_expired/ok" } do
          it "refreshes the token" do
            # One request: Refresh authz
            expect(HTTP).to receive(:post).once.and_call_original
            expect(subject.token).to eq(
              "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6Ik4wSTJRekJEUWpRM04wUkJSakJFUkRVM05qaEZNREF5T0VWRlJqWkRSVVl4TWtFMU5ERXdSUSJ9.eyJzZXJ2aWNlX2FjY291bnRfaWQiOiI5U0VRMDAwMjAwIiwiaXNzIjoiaHR0cHM6Ly9hdXRoLmFjY291bnRzLmRvd2pvbmVzLmNvbS8iLCJzdWIiOiJhdXRoMHw2MWIyNzIwZjFjM2IyMjU2ZDdlMzUyNzYiLCJhdWQiOiJlTnlIckwwQ0xmNEFtRWxnMmZmQjBkcmFmYVVPTndjRyIsImV4cCI6MTY0MzQxODEwMywiaWF0IjoxNjQzMzgyMTAzLCJhenAiOiJlTnlIckwwQ0xmNEFtRWxnMmZmQjBkcmFmYVVPTndjRyJ9.ZTpAV_UrlOClNhURjqLoL6f896E3Kh_xsQKuYn9wgd6O6Py2nQdYmp93fFx_FQi2xeOzTSVDqP_lHtGgytvQ25pTw_J_I_qkjck40XZLvZ6AZaP6wLZ1kJpr_FyFQCVVFc7MnreAmcpLwPrje-AecPJmO65OUdHD-eDvy5fVVs4dbXu9HEQKIb1pzsnDglnRKBUrNVGLjdkabQK5jXQPy9fbridZelJiDaC7Qcli_2qXGxzImOS2vymTNhi6svUUOIRnK63Axlk_IT8-iWdVYk6rIKTRZmIjnE30wx09RO-slMwY7uaUIW2bY9ilET5A7v7UHxoKQni_zxZsOMvq9Q"
            )
          end
        end

        context "Refresh token request fails", vcr: { cassette_name: "token_expired/refresh_authz_fails" } do
          it "raises an exception" do
            # One request: Refresh authz
            expect(HTTP).to receive(:post).once.and_call_original
            expect{
              subject.token
            }.to raise_error(RequestError, { code: 400, error: "invalid_request" }.to_s)
          end
        end
      end
    end
  end
end