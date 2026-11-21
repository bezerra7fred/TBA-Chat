export const getMessageAvatarUrl = ({
  additionalAttributes = {},
  sender = {},
  chatContact = {},
} = {}) =>
  additionalAttributes?.senderAvatarUrl ||
  additionalAttributes?.sender_avatar_url ||
  sender?.thumbnail ||
  sender?.avatarUrl ||
  sender?.avatar_url ||
  chatContact?.thumbnail ||
  chatContact?.avatar_url ||
  '';
