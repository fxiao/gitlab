# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::Otp::SessionEnforcer, :clean_gitlab_redis_shared_state do
  shared_examples_for 'otp session enforcer' do
    let_it_be(:key) { create(:key)}

    describe '#update_session' do
      let(:redis) { double(:redis) }

      before do
        stub_licensed_features(git_two_factor_enforcement: true)
      end

      it 'registers a session in Redis' do
        expect(redis_store_class).to receive(:with).and_yield(redis)
        session_expiry_in_seconds = Gitlab::CurrentSettings.git_two_factor_session_expiry.minutes.to_i

        expect(redis).to(
          receive(:setex)
            .with("#{described_class::OTP_SESSIONS_NAMESPACE}:#{key.id}",
                  session_expiry_in_seconds,
                  true)
            .once)

        described_class.new(key).update_session
      end

      context 'when licensed feature is not available' do
        before do
          stub_licensed_features(git_two_factor_enforcement: false)
        end

        it 'does not register a session in Redis' do
          expect(redis).not_to receive(:setex)

          described_class.new(key).update_session
        end
      end
    end

    describe '#access_restricted?' do
      subject { described_class.new(key).access_restricted? }

      before do
        stub_licensed_features(git_two_factor_enforcement: true)
      end

      context 'with existing session' do
        before do
          redis_store_class.with do |redis|
            redis.set("#{described_class::OTP_SESSIONS_NAMESPACE}:#{key.id}", true )
          end
        end

        it { is_expected.to be_falsey }
      end

      context 'without an existing session' do
        it { is_expected.to be_truthy }
      end
    end
  end

  context 'when ENV[GITLAB_USE_REDIS_SESSIONS_STORE] is true', :clean_gitlab_redis_sessions do
    before do
      stub_env('GITLAB_USE_REDIS_SESSIONS_STORE', 'true')
    end

    it_behaves_like 'otp session enforcer' do
      let(:redis_store_class) { Gitlab::Redis::Sessions }
    end
  end

  context 'when ENV[GITLAB_USE_REDIS_SESSIONS_STORE] is false', :clean_gitlab_redis_sessions do
    before do
      stub_env('GITLAB_USE_REDIS_SESSIONS_STORE', 'false')
    end

    it_behaves_like 'otp session enforcer' do
      let(:redis_store_class) { Gitlab::Redis::SharedState }
    end
  end
end
