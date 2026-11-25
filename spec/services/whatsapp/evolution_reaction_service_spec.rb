require 'rails_helper'

RSpec.describe Whatsapp::EvolutionReactionService do
  let(:base_url) { 'https://evolution.example.test' }
  let(:message_id) { 'wamid.original' }
  let(:message) { instance_double(Message, id: 42, source_id: "WAID:#{message_id}") }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('EVOLUTION_API_URL', '').and_return(base_url)
    allow(ENV).to receive(:fetch).with('EVOLUTION_API_KEY', '').and_return('test-api-key')
    allow(ENV).to receive(:fetch).with('EVOLUTION_INSTANCE', '').and_return('test-instance')
  end

  it 'looks up the original message key and sends only approved key fields' do
    stub_request(:post, "#{base_url}/chat/findMessages/test-instance")
      .to_return(
        status: 200,
        body: {
          messages: {
            records: [
              {
                key: {
                  id: message_id,
                  remoteJid: 'group@g.us',
                  fromMe: true,
                  participant: 'participant@lid',
                  sensitive: 'must-not-be-forwarded'
                }
              }
            ]
          }
        }.to_json
      )
    reaction_request = stub_request(:post, "#{base_url}/message/sendReaction/test-instance")
                       .with do |request|
      payload = JSON.parse(request.body)
      payload['reaction'] == '👍' &&
        payload['key'] == {
          'id' => message_id,
          'remoteJid' => 'group@g.us',
          'fromMe' => true,
          'participant' => 'participant@lid'
        }
    end.to_return(status: 200)

    expect(described_class.new(message: message, reaction: '👍').perform).to be(true)
    expect(reaction_request).to have_been_requested
  end

  it 'returns false when Evolution credentials are missing' do
    allow(ENV).to receive(:fetch).with('EVOLUTION_API_KEY', '').and_return('')

    expect(described_class.new(message: message, reaction: '👍').perform).to be(false)
  end

  it 'does not send when the message source ID is not an Evolution ID' do
    unsupported_message = instance_double(Message, id: 42, source_id: 'wamid.original')

    expect(described_class.new(message: unsupported_message, reaction: '👍').perform).to be(false)
  end
end
