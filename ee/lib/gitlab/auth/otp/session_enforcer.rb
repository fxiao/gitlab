# frozen_string_literal: true

module Gitlab
  module Auth
    module Otp
      class SessionEnforcer
        OTP_SESSIONS_NAMESPACE = 'session:otp'

        def initialize(key)
          @key = key
        end

        def update_session
          self.class.redis_store_class.with do |redis|
            redis.setex(key_name, session_expiry_in_seconds, true)
          end
        end

        def access_restricted?
          self.class.redis_store_class.with do |redis|
            !redis.get(key_name)
          end
        end

        private

        attr_reader :key

        def key_name
          @key_name ||= "#{OTP_SESSIONS_NAMESPACE}:#{key.id}"
        end

        def session_expiry_in_seconds
          Gitlab::CurrentSettings.git_two_factor_session_expiry.minutes.to_i
        end

        # TODO: extract next two methods into some general-purpose method to remove the duplication?
        def self.redis_store_class
          use_redis_session_store? ? Gitlab::Redis::Sessions : Gitlab::Redis::SharedState
        end

        def self.use_redis_session_store?
          Gitlab::Utils.to_boolean(ENV['GITLAB_USE_REDIS_SESSIONS_STORE'], default: true)
        end
      end
    end
  end
end
