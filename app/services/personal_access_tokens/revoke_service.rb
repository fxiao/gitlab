# frozen_string_literal: true

module PersonalAccessTokens
  class RevokeService
    attr_reader :token, :current_user, :group,  :ip_address

    def initialize(current_user = nil, params = { token: nil, group: nil })
      @current_user = current_user
      @token = params[:token]
      @group = params[:group]
      @ip_address = params[:ip_address]
    end

    def execute
      return ServiceResponse.error(message: 'Not permitted to revoke') unless revocation_permitted?

      if token.revoke!
        log_event
        ServiceResponse.success(message: success_message)
      else
        ServiceResponse.error(message: error_message)
      end
    end

    private

    def error_message
      _("Could not revoke personal access token %{personal_access_token_name}.") % { personal_access_token_name: token.name }
    end

    def success_message
      _("Revoked personal access token %{personal_access_token_name}!") % { personal_access_token_name: token.name }
    end

    def revocation_permitted?
      Ability.allowed?(current_user, :revoke_token, token)
    end

    def log_event
      Gitlab::AppLogger.info(_("User %{current_user_username} has revoked personal access token with id %{pat_id} for user %{username}") %
        { current_user_username: current_user.username, pat_id: token.id, username: token.user.username })
    end
  end
end

PersonalAccessTokens::RevokeService.prepend_if_ee('EE::PersonalAccessTokens::RevokeService')
