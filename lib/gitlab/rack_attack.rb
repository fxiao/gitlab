# frozen_string_literal: true

# Integreation specs for throttling can be found in:
# spec/requests/rack_attack_global_spec.rb
module Gitlab
  module RackAttack
    def self.configure(rack_attack)
      # This adds some methods used by our throttles to the `Rack::Request`
      rack_attack::Request.include(Gitlab::RackAttack::Request)
      # Confugure the throttles
      configure_throttles(rack_attack)
    end

    def self.configure_throttles(rack_attack)
      rack_attack.throttle('throttle_unauthenticated', Gitlab::Throttle.unauthenticated_options) do |req|
        if !req.should_be_skipped? &&
           Gitlab::Throttle.settings.throttle_unauthenticated_enabled &&
           req.unauthenticated?
          req.ip
        end
      end

      rack_attack.throttle('throttle_authenticated_api', Gitlab::Throttle.authenticated_api_options) do |req|
        if req.api_request? &&
           Gitlab::Throttle.settings.throttle_authenticated_api_enabled
          req.authenticated_user_id([:api])
        end
      end

      # Product analytics feature is in experimental stage.
      # At this point we want to limit amount of events registered
      # per application (aid stands for application id).
      rack_attack.throttle('throttle_product_analytics_collector', limit: 100, period: 60) do |req|
        if req.product_analytics_collector_request?
          req.params['aid']
        end
      end

      rack_attack.throttle('throttle_authenticated_web', Gitlab::Throttle.authenticated_web_options) do |req|
        if req.web_request? &&
           Gitlab::Throttle.settings.throttle_authenticated_web_enabled
          req.authenticated_user_id([:api, :rss, :ics])
        end
      end

      rack_attack.throttle('throttle_unauthenticated_protected_paths', Gitlab::Throttle.protected_paths_options) do |req|
        if req.post? &&
           !req.should_be_skipped? &&
           req.protected_path? &&
           Gitlab::Throttle.protected_paths_enabled? &&
           req.unauthenticated?
          req.ip
        end
      end

      rack_attack.throttle('throttle_authenticated_protected_paths_api', Gitlab::Throttle.protected_paths_options) do |req|
        if req.post? &&
           req.api_request? &&
           req.protected_path? &&
           Gitlab::Throttle.protected_paths_enabled?
          req.authenticated_user_id([:api])
        end
      end

      rack_attack.throttle('throttle_authenticated_protected_paths_web', Gitlab::Throttle.protected_paths_options) do |req|
        if req.post? &&
           req.web_request? &&
           req.protected_path? &&
           Gitlab::Throttle.protected_paths_enabled?
          req.authenticated_user_id([:api, :rss, :ics])
        end
      end

      rack_attack.safelist('throttle_bypass_header') do |req|
        Gitlab::Throttle.bypass_header.present? &&
          req.get_header(Gitlab::Throttle.bypass_header) == '1'
      end
    end
  end
end
::Gitlab::RackAttack.prepend_if_ee('::EE::Gitlab::RackAttack')
