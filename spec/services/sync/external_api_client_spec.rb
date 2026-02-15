# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sync::ExternalApiClient do
  let(:base_url) { "http://external-api.test" }
  let(:client) { described_class.new(base_url: base_url) }

  it "parses and returns JSON on success" do
    stub_request(:get, "#{base_url}/todolists")
      .to_return(status: 200, body: [{ "id" => "ext-1", "name" => "Test" }].to_json,
                 headers: { "Content-Type" => "application/json" })

    result = client.fetch_all_lists

    expect(result).to eq([{ "id" => "ext-1", "name" => "Test" }])
  end

  it "raises ApiError with status and body on failure" do
    stub_request(:get, "#{base_url}/todolists")
      .to_return(status: 500, body: { "error" => "Internal" }.to_json,
                 headers: { "Content-Type" => "application/json" })

    expect { client.fetch_all_lists }.to raise_error(Sync::ExternalApiClient::ApiError) { |e|
      expect(e.status).to eq(500)
      expect(e.body).to eq({ "error" => "Internal" })
    }
  end

  it "retries on transient connection failures" do
    stub_request(:get, "#{base_url}/todolists")
      .to_timeout
      .then.to_return(status: 200, body: [].to_json,
                      headers: { "Content-Type" => "application/json" })

    result = client.fetch_all_lists

    expect(result).to eq([])
  end
end
