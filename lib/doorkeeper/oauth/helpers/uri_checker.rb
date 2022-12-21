module Doorkeeper
  module OAuth
    module Helpers
      module URIChecker
        def self.valid?(url)
          # since preauthorization is allowing native uri https://github.com/mt-max/doorkeeper/blob/current/lib/doorkeeper/oauth/pre_authorization.rb#L65
          # we should allow it during token exchange as well https://github.com/mt-max/doorkeeper/blob/current/lib/doorkeeper/oauth/authorization_code_request.rb#L55
          # 
          # this is how current latest doorkeeper is supporting it
          # https://github.com/doorkeeper-gem/doorkeeper/blob/2533ab92e9ee337f52bbab2b2201d791a19a7633/lib/doorkeeper/oauth/helpers/uri_checker.rb#L10
          return true if native_uri?(url)

          uri = as_uri(url)
          uri.fragment.nil? && !uri.host.nil? && !uri.scheme.nil?
        rescue URI::InvalidURIError
          false
        end

        def self.matches?(url, client_url)
          url = as_uri(url)
          client_url = as_uri(client_url)

          if client_url.query.present?
            return false unless query_matches?(url.query, client_url.query)
            # Clear out queries so rest of URI can be tested. This allows query
            # params to be in the request but order not mattering.
            client_url.query = nil
          end
          url.query = nil
          url == client_url
        end

        def self.valid_for_authorization?(url, client_url)
          valid?(url) && client_url.split.any? { |other_url| matches?(url, other_url) }
        end

        def self.as_uri(url)
          URI.parse(url)
        end

        def self.query_matches?(query, client_query)
          return true if client_query.nil? && query.nil?
          return false if client_query.nil? || query.nil?
          # Will return true independent of query order
          client_query.split('&').sort == query.split('&').sort
        end

        def self.native_uri?(url)
          url == Doorkeeper.configuration.native_redirect_uri
        end
      end
    end
  end
end
