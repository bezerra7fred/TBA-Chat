import { findWhatsAppInboxOption } from '../contactConversationHelper';

describe('findWhatsAppInboxOption', () => {
  it('selects the inbox named whatsapp, including custom API inboxes', () => {
    const email = {
      id: 1,
      name: 'Support',
      label: 'Support',
      channelType: 'Channel::Email',
    };
    const whatsapp = {
      id: 2,
      name: 'whatsapp',
      label: 'whatsapp',
      channelType: 'Channel::Api',
      sourceId: 'server-generated-source-id',
    };

    expect(findWhatsAppInboxOption([email, whatsapp])).toBe(whatsapp);
  });

  it('prefers an exact WhatsApp label when native and custom inboxes exist', () => {
    const nativeInbox = {
      id: 1,
      name: 'Business line',
      label: 'Business line (+15551234567)',
      channelType: 'Channel::Whatsapp',
    };
    const customInbox = {
      id: 2,
      name: 'whatsapp',
      label: 'whatsapp',
      channelType: 'Channel::Api',
    };

    expect(findWhatsAppInboxOption([nativeInbox, customInbox])).toBe(
      customInbox
    );
  });

  it('recognizes Twilio WhatsApp by medium or its WhatsApp address', () => {
    const twilioInbox = {
      id: 3,
      name: 'WhatsApp outbound',
      label: 'WhatsApp outbound',
      channelType: 'Channel::TwilioSms',
      medium: 'whatsapp',
    };
    const smsInbox = {
      id: 4,
      name: 'SMS',
      label: 'SMS',
      channelType: 'Channel::TwilioSms',
      medium: 'sms',
    };

    expect(findWhatsAppInboxOption([smsInbox, twilioInbox])).toBe(twilioInbox);
    expect(
      findWhatsAppInboxOption([
        {
          id: 5,
          name: 'Legacy',
          label: 'Legacy',
          channelType: 'Channel::TwilioSms',
          phoneNumber: 'whatsapp:+15551234567',
        },
      ])
    ).toEqual(expect.objectContaining({ id: 5 }));
  });

  it('returns undefined if there is no WhatsApp choice', () => {
    expect(
      findWhatsAppInboxOption([
        {
          id: 1,
          name: 'Support',
          label: 'Support',
          channelType: 'Channel::Email',
        },
      ])
    ).toBeUndefined();
  });
});
