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

  it('returns undefined when no WhatsApp inbox is available', () => {
    expect(
      getWhatsAppContactableInbox([
        { inbox: { id: 1, channel_type: 'Channel::Email' } },
      ])
    ).toBeUndefined();
  });
});
