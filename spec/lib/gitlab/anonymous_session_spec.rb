# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::AnonymousSession do
  let(:default_session_id) { '6919a6f1bb119dd7396fadc38fd18d0d' }
  let(:additional_session_id) { '7919a6f1bb119dd7396fadc38fd18d0d' }

  subject { new_anonymous_session }

  def new_anonymous_session
    described_class.new('127.0.0.1')
  end

  RSpec.shared_examples_for 'anonymous sessions' do
    describe '#store_session_ip' do
      it 'adds session id to proper key' do
        subject.count_session_ip

        redis_store_class.with do |redis|
          expect(redis.get("session:lookup:ip:gitlab2:127.0.0.1").to_i).to eq 1
        end
      end

      it 'adds expiration time to key' do
        freeze_time do
          subject.count_session_ip

          redis_store_class.with do |redis|
            expect(redis.ttl("session:lookup:ip:gitlab2:127.0.0.1")).to eq(24.hours.to_i)
          end
        end
      end

      context 'when there is already one session' do
        it 'increments the session count' do
          subject.count_session_ip
          new_anonymous_session.count_session_ip

          redis_store_class.with do |redis|
            expect(redis.get("session:lookup:ip:gitlab2:127.0.0.1").to_i).to eq(2)
          end
        end
      end
    end

    describe '#stored_sessions' do
      it 'returns all anonymous sessions per ip' do
        redis_store_class.with do |redis|
          redis.set("session:lookup:ip:gitlab2:127.0.0.1", 2)
        end

        expect(subject.session_count).to eq(2)
      end
    end

    it 'removes obsolete lookup through ip entries' do
      Gitlab::Redis::Sessions.with do |redis|
        redis.set("session:lookup:ip:gitlab2:127.0.0.1", 2)
      end

      subject.cleanup_session_per_ip_count

      Gitlab::Redis::Sessions.with do |redis|
        expect(redis.exists("session:lookup:ip:gitlab2:127.0.0.1")).to eq(false)
      end
    end
  end

  context 'when ENV[GITLAB_USE_REDIS_SESSIONS_STORE] is true', :clean_gitlab_redis_sessions do
    before do
      stub_env('GITLAB_USE_REDIS_SESSIONS_STORE', 'true')
    end

    it_behaves_like 'anonymous sessions' do
      let(:redis_store_class) { Gitlab::Redis::Sessions }
    end
  end

  context 'when ENV[GITLAB_USE_REDIS_SESSIONS_STORE] is false', :clean_gitlab_redis_shared_state do
    before do
      stub_env('GITLAB_USE_REDIS_SESSIONS_STORE', 'false')
    end

    it_behaves_like 'anonymous sessions' do
      let(:redis_store_class) { Gitlab::Redis::SharedState }
    end
  end
end
