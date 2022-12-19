require 'doorkeeper/request/strategy'

module Doorkeeper
  module Request
    class AuthorizationCode < Strategy
      delegate :client, :parameters, to: :server

      def request
        @request ||= OAuth::AuthorizationCodeRequest.new(
          Doorkeeper.configuration,
          grant,
          client,
          parameters
        )
      end

      private

      def grant
        Doorkeeper.configuration.access_grant_model.by_token(parameters[:code])
      end
    end
  end
end
