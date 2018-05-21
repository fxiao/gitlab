module Gitlab
  module Auth
    module GroupSaml
      class GroupLookup
        def initialize(env)
          @env = env
        end

        def path
          path_from_callback_path || path_from_params
        end

        def group
          Group.find_by_full_path(path)
        end

        def saml_provider
          group&.saml_provider
        end

        def group_saml_enabled?
          saml_provider && group.feature_available?(:group_saml)
        end

        def token_discoverable?
          return unless group_discovery_token.present?

          group_discovery_token == params['token']
        end

        private

        attr_reader :env

        def group_discovery_token
          group&.saml_discovery_token
        end

        def path_from_callback_path
          path = env['PATH_INFO']
          path_regex = Gitlab::PathRegex.saml_callback_regex

          path.match(path_regex).try(:[], :group)
        end

        def params
          @params ||= Rack::Request.new(env).params
        end

        def path_from_params
          params['group_path']
        end
      end
    end
  end
end
