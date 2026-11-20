import { buildWhatsAppContactableInboxes } from '../contactConversationHelper';

describe('buildWhatsAppContactableInboxes', () => {
  it('builds a WhatsApp inbox choice from account inboxes and a phone number', () => {
    const accountInboxes = [
      { id: 1, channel_type: 'Channel::Email' },
      { id: 2, channel_type: 'Channel::Whatsapp', name: 'Sales' },
    ];

    expect(
      buildWhatsAppContactableInboxes(accountInboxes, '+5511987654321')
    ).toEqual([
      {
        id: 2,
        channelType: 'Channel::Whatsapp',
        name: 'Sales',
        sourceId: '5511987654321',
      },
    ]);
  });

  it('creates the Twilio WhatsApp source id without a contact-inbox row', () => {
    const accountInboxes = [
      {
        id: 3,
        channel_type: 'Channel::TwilioSms',
        medium: 'whatsapp',
        phone_number: 'whatsapp:+15551234567',
      },
    ];

    expect(
      buildWhatsAppContactableInboxes(accountInboxes, '+5511987654321')
    ).toEqual([
      {
        id: 3,
        channelType: 'Channel::TwilioSms',
        medium: 'whatsapp',
        phoneNumber: 'whatsapp:+15551234567',
        sourceId: 'whatsapp:+5511987654321',
      },
    ]);
  });

  it('recognizes Twilio WhatsApp by its address when medium is omitted', () => {
    const accountInboxes = [
      {
        id: 4,
        channel_type: 'Channel::TwilioSms',
        phone_number: 'whatsapp:+15551234567',
      },
    ];

    expect(
      buildWhatsAppContactableInboxes(accountInboxes, '+14155552671')
    ).toEqual([
      expect.objectContaining({
        id: 4,
        sourceId: 'whatsapp:+14155552671',
      }),
    ]);
  });

  it('does not return non-WhatsApp inboxes or choices without a phone number', () => {
    const accountInboxes = [
      { id: 1, channel_type: 'Channel::Email' },
      { id: 2, channel_type: 'Channel::TwilioSms', medium: 'sms' },
    ];

    expect(
      buildWhatsAppContactableInboxes(accountInboxes, '+5511987654321')
    ).toEqual([]);
    expect(
      buildWhatsAppContactableInboxes(
        [{ id: 3, channel_type: 'Channel::Whatsapp' }],
        ''
      )
    ).toEqual([]);
  });
});
