# frozen_string_literal: true

module Sync
  class ExternalApiClient
    LOG_TAG = '[Sync::ExternalApiClient]'

    class ApiError < StandardError
      attr_reader :status, :body

      def initialize(message, status: nil, body: nil)
        @status = status
        @body = body
        super(message)
      end
    end

    def initialize(base_url: nil)
      @base_url = base_url || ENV.fetch('SYNC_API_BASE_URL', 'http://localhost:4000')
      @connection = build_connection
    end

    # GET /todolists — returns all lists with nested items
    def fetch_all_lists
      response = @connection.get('todolists')
      handle_response(response)
    end

    # POST /todolists — create list with optional items
    def create_list(source_id:, name:, items: [])
      body = { source_id: source_id.to_s, name: name }
      if items.any?
        body[:items] = items.map do |item|
          { source_id: item[:source_id].to_s,
            description: item[:description],
            completed: item[:completed] }
        end
      end
      response = @connection.post('todolists', body)
      handle_response(response)
    end

    # PATCH /todolists/:id
    def update_list(external_id:, name:)
      response = @connection.patch("todolists/#{external_id}", { name: name })
      handle_response(response)
    end

    # DELETE /todolists/:id
    def delete_list(external_id:)
      response = @connection.delete("todolists/#{external_id}")
      handle_response(response)
    end

    # PATCH /todolists/:list_id/todoitems/:item_id
    def update_item(list_external_id:, item_external_id:, description:, completed:)
      response = @connection.patch(
        "todolists/#{list_external_id}/todoitems/#{item_external_id}",
        { description: description, completed: completed }
      )
      handle_response(response)
    end

    # DELETE /todolists/:list_id/todoitems/:item_id
    def delete_item(list_external_id:, item_external_id:)
      response = @connection.delete(
        "todolists/#{list_external_id}/todoitems/#{item_external_id}"
      )
      handle_response(response)
    end

    private

    def build_connection
      Faraday.new(url: @base_url) do |f|
        f.request :json
        f.response :json
        f.request :retry, max: 3, interval: 0.5,
                          interval_randomness: 0.5,
                          backoff_factor: 2,
                          exceptions: [Faraday::TimeoutError, Faraday::ConnectionFailed]
        f.response :logger, Rails.logger, headers: false, bodies: false
        f.adapter Faraday.default_adapter
      end
    end

    def handle_response(response)
      return response.body if response.success?

      Rails.logger.error("#{LOG_TAG} API error: status=#{response.status} body=#{response.body}")
      raise ApiError.new(
        "External API returned #{response.status}",
        status: response.status,
        body: response.body
      )
    end
  end
end
