import { INBOX_TYPES } from 'dashboard/helper/inbox';
import camelcaseKeys from 'camelcase-keys';

const isWhatsAppInbox = inbox => {
  const { channelType, medium, phoneNumber = '' } = inbox;
  return (
    channelType === INBOX_TYPES.WHATSAPP ||
    (channelType === INBOX_TYPES.TWILIO &&
      (medium === 'whatsapp' || /^whatsapp:/i.test(phoneNumber)))
  );
};

export const buildWhatsAppContactableInboxes = (inboxes, contactPhone) => {
  const phoneNumber = String(contactPhone || '').trim();
  if (!phoneNumber) return [];

  return inboxes
    .map(inbox => camelcaseKeys(inbox, { deep: true }))
    .filter(isWhatsAppInbox)
    .map(inbox => ({
      ...inbox,
      // Match the ContactableInboxesService source IDs without requiring an
      // existing contact_inbox row for this phone number.
      sourceId:
        inbox.channelType === INBOX_TYPES.TWILIO
          ? `whatsapp:${phoneNumber}`
          : phoneNumber.replace(/\+/g, ''),
    }));
};
