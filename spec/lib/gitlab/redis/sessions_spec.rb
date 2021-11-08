# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::Sessions, :clean_gitlab_redis_sessions do
  before do
    stub_env('GITLAB_USE_REDIS_SESSIONS_STORE', 'true')
  end

  include_examples "redis_new_instance_shared_examples", 'sessions', Gitlab::Redis::SharedState
end
