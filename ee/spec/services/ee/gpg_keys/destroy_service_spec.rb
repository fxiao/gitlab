# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GpgKeys::DestroyService do
  let_it_be(:user) { create(:user) }

  subject { described_class.new(user) }

  it 'creates an audit event', :aggregate_failures do
    key = create(:personal_key)

    expect { subject.execute(key) }.to change(AuditEvent, :count).by(1)

    expect(AuditEvent.last).to have_attributes(
      author: user,
      entity_id: key.user.id,
      target_id: key.id,
      target_type: key.class.name,
      target_details: key.title,
      details: include(custom_message: 'Removed GPG key')
    )
  end

  it 'returns the correct value' do
    key = build(:gpg_key)
    allow(key).to receive(:destroy).and_return(true)

    expect(subject.execute(key)).to eq(true)
  end

  context 'when destroy operation fails' do
    let(:key) { build(:gpg_key) }

    before do
      allow(key).to receive(:destroy).and_return(false)
    end

    it 'does not create an audit event' do
      expect { subject.execute(key) }.not_to change(AuditEvent, :count)
    end

    it 'returns the correct value' do
      expect(subject.execute(key)).to eq(false)
    end
  end
end
