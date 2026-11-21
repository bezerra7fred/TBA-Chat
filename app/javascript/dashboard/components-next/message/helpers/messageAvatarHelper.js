export const getMessageAvatarUrl = ({
  additionalAttributes = {},
  sender = {},
  chatContact = {},
} = {}) => {
  const senderAvatar =
    sender?.thumbnail || sender?.avatarUrl || sender?.avatar_url || '';
  const isGroupParticipant =
    sender?.groupParticipant || sender?.group_participant;

  // A group participant without a contact photo must not inherit the group contact's photo.
  if (isGroupParticipant) return senderAvatar;

  return (
    additionalAttributes?.senderAvatarUrl ||
    additionalAttributes?.sender_avatar_url ||
    senderAvatar ||
    chatContact?.thumbnail ||
    chatContact?.avatar_url ||
    ''
  );
};
