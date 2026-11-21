import { getMessageAvatarUrl } from '../messageAvatarHelper';

describe('getMessageAvatarUrl', () => {
  it.each(['senderAvatarUrl', 'sender_avatar_url'])(
    'prefers the per-message %s over the group avatar', attribute => {
      expect(
        getMessageAvatarUrl({
          additionalAttributes: { [attribute]: 'member-avatar.png' },
          sender: { thumbnail: 'group-avatar.png' },
          chatContact: { thumbnail: 'group-avatar.png' },
        })
      ).toBe('member-avatar.png');
    }
  );

  it('falls back to the sender and then the conversation contact avatar', () => {
    expect(
      getMessageAvatarUrl({
        sender: { avatar_url: 'sender-avatar.png' },
        chatContact: { thumbnail: 'contact-avatar.png' },
      })
    ).toBe('sender-avatar.png');

    expect(
      getMessageAvatarUrl({ chatContact: { thumbnail: 'contact-avatar.png' } })
    ).toBe('contact-avatar.png');
  });

  it('returns an empty URL when no avatar is available', () => {
    expect(getMessageAvatarUrl()).toBe('');
  });
});
