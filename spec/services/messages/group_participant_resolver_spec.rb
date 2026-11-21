# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Messages::GroupParticipantResolver do
  let(:account) { create(:account) }
  let(:api_channel) { create(:channel_api, account: account) }
  let(:inbox) { api_channel.inbox }
  let(:group_contact) { create(:contact, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: group_contact) }
  let(:member) { create(:contact, account: account, name: 'Member Contact', phone_number: '+14155550123') }
  let(:message) do
    create(
      :message,
      account: account,
      inbox: inbox,
      conversation: conversation,
      sender: group_contact,
      content: '**+1 (415) 555-0123 - Member Name:** hello'
    )
  end

  describe '.resolve' do
    it 'serializes the contact and avatar identified by the group-message prefix' do
      member.avatar.attach(
        io: Rails.root.join('spec/assets/avatar.png').open,
        filename: 'avatar.png',
        content_type: 'image/png'
      )

      sender = described_class.resolve(message)

      expect(sender).to include(
        id: member.id,
        name: 'Member Contact',
        phone_number: '+14155550123',
        type: 'contact',
        group_participant: true
      )
      expect(sender[:thumbnail]).to eq(member.avatar_url)
    end

    it 'resolves a collection of historical messages in one pass' do
      member

      described_class.resolve_all([message])

      expect(message.sender_data).to include(id: member.id, group_participant: true)
    end

    it 'uses the member data in real-time message event payloads' do
      member

      expect(message.push_event_data[:sender]).to include(
        id: member.id,
        group_participant: true
      )
    end

    it 'marks an unresolved participant without using the group contact as sender' do
      sender = described_class.resolve(message)

      expect(sender).to include(
        name: 'Member Name',
        phone_number: '+14155550123',
        thumbnail: '',
        type: 'contact',
        group_participant: true
      )
    end

    it 'does not resolve messages outside API inboxes' do
      message.update!(inbox: create(:inbox, account: account))

      expect(described_class.resolve(message)).to be_nil
    end

    it 'does not resolve ordinary API messages without a participant prefix' do
      message.update!(content: 'A regular API message')

      expect(described_class.resolve(message)).to be_nil
    end
  end
end
