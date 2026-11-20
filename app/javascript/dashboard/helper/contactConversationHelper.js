import { INBOX_TYPES } from 'dashboard/helper/inbox';

export const getWhatsAppContactableInbox = contactableInboxes =>
  contactableInboxes.find(({ inbox = {} }) => {
    const channelType = inbox.channel_type || inbox.channelType;
    const isWhatsAppChannel = channelType === INBOX_TYPES.WHATSAPP;
    const isTwilioWhatsApp =
      channelType === INBOX_TYPES.TWILIO && inbox.medium === 'whatsapp';

    return isWhatsAppChannel || isTwilioWhatsApp;
  });
