import { getWhatsAppContactableInbox } from '../contactConversationHelper';

describe('getWhatsAppContactableInbox', () => {
  it('selects a WhatsApp inbox, skipping other channel types', () => {
    const emailInbox = { inbox: { id: 1, channel_type: 'Channel::Email' } };
    const whatsappInbox = {
      inbox: { id: 2, channel_type: 'Channel::Whatsapp' },
    };

    expect(
      getWhatsAppContactableInbox([emailInbox, whatsappInbox])
    ).toBe(whatsappInbox);
  });

  it('accepts Twilio inboxes configured for WhatsApp, but not SMS', () => {
    const twilioSmsInbox = {
      inbox: {
        id: 1,
        channel_type: 'Channel::TwilioSms',
        medium: 'sms',
      },
    };
    const twilioWhatsAppInbox = {
      inbox: {
        id: 2,
        channel_type: 'Channel::TwilioSms',
        medium: 'whatsapp',
      },
    };

    expect(
      getWhatsAppContactableInbox([twilioSmsInbox, twilioWhatsAppInbox])
    ).toBe(twilioWhatsAppInbox);
  });

  it('accepts the camel-cased contactable inbox payload used by the composer', () => {
    const whatsappInbox = {
      inbox: { id: 3, channelType: 'Channel::Whatsapp' },
    };

    expect(getWhatsAppContactableInbox([whatsappInbox])).toBe(whatsappInbox);
  });

  it('recognizes Twilio WhatsApp from its address when medium is missing', () => {
    const twilioWhatsAppInbox = {
      inbox: {
        id: 4,
        channel_type: 'Channel::TwilioSms',
        phone_number: 'whatsapp:+15551234567',
      },
    };

    expect(getWhatsAppContactableInbox([twilioWhatsAppInbox])).toBe(
      twilioWhatsAppInbox
    );
  });

  it('returns undefined when no WhatsApp inbox is available', () => {
    expect(
      getWhatsAppContactableInbox([
        { inbox: { id: 1, channel_type: 'Channel::Email' } },
      ])
    ).toBeUndefined();
  });
});
