module Doorkeeper
  class TokensController < Doorkeeper::ApplicationMetalController
    def create
      response = authorize_response
      headers.merge! response.headers
      self.response_body = response.body.to_json
      self.status        = response.status
    rescue Errors::DoorkeeperError => e
      handle_token_exception e
    end

     # OAuth 2.0 Token Revocation - https://datatracker.ietf.org/doc/html/rfc7009
     def revoke
      # The authorization server responds with HTTP status code 200 if the client
      # submitted an invalid token or the token has been revoked successfully.
      if token.blank?
        render json: {}, status: 200
      # The authorization server validates [...] and whether the token
      # was issued to the client making the revocation request. If this
      # validation fails, the request is refused and the client is informed
      # of the error by the authorization server as described below.
      elsif authorized?
        revoke_token
        render json: {}, status: 200
      else
        render json: revocation_error_response, status: :forbidden
      end
    end

    private

    # OAuth 2.0 Section 2.1 defines two client types, "public" & "confidential".
    #
    # RFC7009
    # Section 5. Security Considerations
    # A malicious client may attempt to guess valid tokens on this endpoint
    # by making revocation requests against potential token strings.
    # According to this specification, a client's request must contain a
    # valid client_id, in the case of a public client, or valid client
    # credentials, in the case of a confidential client. The token being
    # revoked must also belong to the requesting client.
    #
    # Once a confidential client is authenticated, it must be authorized to
    # revoke the provided access or refresh token. This ensures one client
    # cannot revoke another's tokens.
    #
    # Doorkeeper determines the client type implicitly via the presence of the
    # OAuth client associated with a given access or refresh token. Since public
    # clients authenticate the resource owner via "password" or "implicit" grant
    # types, they set the application_id as null (since the claim cannot be
    # verified).
    #
    # https://datatracker.ietf.org/doc/html/rfc6749#section-2.1
    # https://datatracker.ietf.org/doc/html/rfc7009
    def authorized?
      # Token belongs to specific client, so we need to check if
      # authenticated client could access it.
      if token.application_id? && token.application.confidential?
        # We authorize client by checking token's application
        server.client && server.client.application == token.application
      else
        # Token was issued without client, authorization unnecessary
        true
      end
    end

    def revoke_token
      # The authorization server responds with HTTP status code 200 if the token
      # has been revoked successfully or if the client submitted an invalid
      # token
      token.revoke if token&.accessible?
    end

    def token
      @token ||=
        if params[:token_type_hint] == 'refresh_token'
          Doorkeeper.configuration.access_token_model.by_refresh_token(params['token'])
        else
          Doorkeeper.configuration.access_token_model.by_token(params['token']) ||
          Doorkeeper.configuration.access_token_model.by_refresh_token(params['token'])
        end
    end

    def strategy
      @strategy ||= server.token_request params[:grant_type]
    end

    def authorize_response
      @authorize_response ||= strategy.authorize
    end

    def revocation_error_response
      error_description = I18n.t(:unauthorized, scope: %i[doorkeeper errors messages revoke])

      { error: :unauthorized_client, error_description: error_description }
    end
  end
end
