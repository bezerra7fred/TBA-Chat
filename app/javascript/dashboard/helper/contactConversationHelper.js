import { INBOX_TYPES } from 'dashboard/helper/inbox';

const includesWhatsApp = value =>
  String(value || '')
    .trim()
    .toLowerCase()
    .includes('whatsapp');

const isWhatsAppChannel = ({ channelType, medium, phoneNumber }) =>
  channelType === INBOX_TYPES.WHATSAPP ||
  (channelType === INBOX_TYPES.TWILIO &&
    (medium === 'whatsapp' || /^whatsapp:/i.test(phoneNumber || '')));

// Match the option the user sees in the compose modal's "Via" dropdown.
// Some accounts expose their WhatsApp channel as a custom API inbox named
// "whatsapp", so checking channel_type alone misses the selectable inbox.
export const findWhatsAppInboxOption = inboxOptions => {
  const exactNameMatch = inboxOptions.find(
    option =>
      String(option.name || '').trim().toLowerCase() === 'whatsapp' ||
      String(option.label || '').trim().toLowerCase() === 'whatsapp'
  );
  if (exactNameMatch) return exactNameMatch;

  return (
    inboxOptions.find(isWhatsAppChannel) ||
    inboxOptions.find(
      option =>
        includesWhatsApp(option.name) || includesWhatsApp(option.label)
    )
  );
};
