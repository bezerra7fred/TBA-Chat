import { INBOX_TYPES } from 'dashboard/helper/inbox';

export const getWhatsAppContactableInbox = contactableInboxes =>
  contactableInboxes.find(({ inbox }) => {
    const isWhatsAppChannel = inbox.channel_type === INBOX_TYPES.WHATSAPP;
    const isTwilioWhatsApp =
      inbox.channel_type === INBOX_TYPES.TWILIO && inbox.medium === 'whatsapp';

    return isWhatsAppChannel || isTwilioWhatsApp;
  });
