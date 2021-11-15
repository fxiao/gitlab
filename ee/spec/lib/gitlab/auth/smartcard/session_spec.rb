# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::Smartcard::Session do
  RSpec.shared_examples_for 'smartcard session' do
    describe '#active?' do
      let(:user) { create(:user) }

      subject { described_class.new.active?(user) }

      context 'with a smartcard session', :clean_gitlab_redis_shared_state do
        let(:session_id) { '42' }
        let(:stored_session) do
          { 'smartcard_signins' => { 'last_signin_at' => 5.minutes.ago } }
        end

        before do
          redis_store_class.with do |redis|
            redis.set("session:gitlab:#{session_id}", Marshal.dump(stored_session))
            redis.sadd("session:lookup:user:gitlab:#{user.id}", [session_id])
          end
        end

        it { is_expected.to be_truthy }
      end

      context 'without any session' do
        it { is_expected.to be_falsey }
      end
    end

    describe '#update_active' do
      let(:now) { Time.now }

      around do |example|
        Gitlab::Session.with_session({}) do
          example.run
        end
      end

      it 'stores the time of last sign-in' do
        subject.update_active(now)

        expect(Gitlab::Session.current[:smartcard_signins]).to eq({ 'last_signin_at' => now })
      end
    end
  end

  context 'when ENV[GITLAB_USE_REDIS_SESSIONS_STORE] is true', :clean_gitlab_redis_sessions do
    before do
      stub_env('GITLAB_USE_REDIS_SESSIONS_STORE', 'true')
    end

    it_behaves_like 'smartcard session' do
      let(:redis_store_class) { Gitlab::Redis::Sessions }
    end
  end

  context 'when ENV[GITLAB_USE_REDIS_SESSIONS_STORE] is false', :clean_gitlab_redis_sessions do
    before do
      stub_env('GITLAB_USE_REDIS_SESSIONS_STORE', 'false')
    end

    it_behaves_like 'smartcard session' do
      let(:redis_store_class) { Gitlab::Redis::SharedState }
    end
  end
end
