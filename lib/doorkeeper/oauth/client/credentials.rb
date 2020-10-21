module Doorkeeper
  module OAuth
    class Client
      class Credentials < Struct.new(:uid, :secret)
        class << self
          def from_request(request, *credentials_methods)
            credentials_methods.inject(nil) do |credentials, method|
              method = self.method(method) if method.is_a?(Symbol)
              credentials = Credentials.new(*method.call(request))
              break credentials unless credentials.blank?
            end
          end

          def from_params(request)
            request.parameters.values_at(:client_id, :client_secret)
          end

          def from_basic(request)
            authorization = request.authorization
            if authorization.present? && authorization =~ /^Basic (.*)/m
              Base64.decode64($1).split(/:/, 2)
            end
          end
        end

        # https://github.com/doorkeeper-gem/doorkeeper/blob/master/lib/doorkeeper/oauth/client/credentials.rb
        # Public clients may have their secret blank, but "credentials" are
        # still present
        delegate :blank?, to: :uid
      end
    end
  end
end
