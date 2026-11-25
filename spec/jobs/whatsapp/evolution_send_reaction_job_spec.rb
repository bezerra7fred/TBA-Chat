require 'rails_helper'

RSpec.describe Whatsapp::EvolutionSendReactionJob do
  describe '#perform' do
    it 'sends the requested reaction through the Evolution service' do
      message = instance_double(Message)
      service = instance_double(Whatsapp::EvolutionReactionService)
      allow(Message).to receive(:find_by).with(id: 42).and_return(message)
      allow(Whatsapp::EvolutionReactionService).to receive(:new)
        .with(message: message, reaction: '👍').and_return(service)
      expect(service).to receive(:perform)

      described_class.perform_now(42, '👍')
    end

    it 'does nothing when the message no longer exists' do
      allow(Message).to receive(:find_by).with(id: 42).and_return(nil)
      expect(Whatsapp::EvolutionReactionService).not_to receive(:new)

      described_class.perform_now(42, '👍')
    end
  end
end
