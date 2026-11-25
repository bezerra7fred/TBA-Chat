# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Channel::Api do
  # This validation happens in ApplicationRecord
  describe 'length validations' do
    let(:channel_api) { create(:channel_api) }

    context 'when it validates webhook_url length' do
      it 'valid when within limit' do
        channel_api.webhook_url = 'a' * Limits::URL_LENGTH_LIMIT
        expect(channel_api.valid?).to be true
      end

      it 'invalid when crossed the limit' do
        channel_api.webhook_url = 'a' * (Limits::URL_LENGTH_LIMIT + 1)
        channel_api.valid?
        expect(channel_api.errors[:webhook_url]).to include("is too long (maximum is #{Limits::URL_LENGTH_LIMIT} characters)")
      end
    end
  end

  describe 'reaction support' do
    let(:channel_api) { create(:channel_api) }
    let(:message) { instance_double(Message, id: 42, source_id: 'WAID:wamid.original') }

    it 'supports Evolution-backed WhatsApp messages' do
      expect(channel_api.supports_reactions?(message)).to be(true)
    end

    it 'queues a reaction for supported messages' do
      expect(Whatsapp::EvolutionSendReactionJob).to receive(:perform_later).with(42, '👍')

      expect(channel_api.send_reaction('contact-id', message, '👍')).to be(true)
    end

    it 'queues an empty reaction when removing a reaction' do
      expect(Whatsapp::EvolutionSendReactionJob).to receive(:perform_later).with(42, '')

      expect(channel_api.remove_reaction('contact-id', message, '👍')).to be(true)
    end

    it 'rejects messages without an Evolution source ID' do
      unsupported_message = instance_double(Message, id: 42, source_id: 'wamid.original')

      expect(Whatsapp::EvolutionSendReactionJob).not_to receive(:perform_later)
      expect(channel_api.supports_reactions?(unsupported_message)).to be(false)
      expect(channel_api.send_reaction('contact-id', unsupported_message, '👍')).to be(false)
    end
  end
end
