import { mount } from '@vue/test-utils';
import MessageReactions from '../MessageReactions.vue';

const store = vi.hoisted(() => ({
  dispatch: vi.fn(),
  getters: { getCurrentUserID: 9 },
}));

vi.mock('vuex', () => ({ useStore: () => store }));
vi.mock('vue-i18n', () => ({ useI18n: () => ({ t: key => key }) }));
vi.mock('dashboard/composables', () => ({ useAlert: vi.fn() }));

const mountedWrappers = [];
const mountReactions = (reactions, alignRight = false) => {
  const wrapper = mount(MessageReactions, {
    props: { messageId: 42, conversationId: 17, reactions, alignRight },
    global: {
      stubs: {
        Avatar: {
          props: ['name', 'src', 'size'],
          template: '<span class="avatar" />',
        },
      },
    },
  });
  mountedWrappers.push(wrapper);
  return wrapper;
};

describe('MessageReactions', () => {
  beforeEach(() => {
    store.dispatch.mockReset();
  });

  afterEach(() => {
    mountedWrappers.splice(0).forEach(wrapper => wrapper.unmount());
  });

  it('shows who reacted beside the emoji', () => {
    const wrapper = mountReactions([
      { emoji: '👍', userId: 4, userName: 'Ana' },
      { emoji: '👍', userId: 5, userName: 'Bruno' },
    ]);

    expect(wrapper.text()).toContain('Ana, Bruno');
  });

  it('shows a readable label beside the add reaction icon', () => {
    const wrapper = mountReactions([]);

    expect(
      wrapper.get('button[aria-label="CONVERSATION.REACTIONS.ADD"]').text()
    ).toContain('CONVERSATION.REACTIONS.LABEL');
  });

  it('opens the emoji picker toward the center of the conversation', async () => {
    const incomingMessage = mountReactions([]);
    await incomingMessage
      .get('button[aria-label="CONVERSATION.REACTIONS.ADD"]')
      .trigger('click');

    expect(incomingMessage.get('.absolute.bottom-full').classes()).toContain(
      'start-0'
    );

    const outgoingMessage = mountReactions([], true);
    await outgoingMessage
      .get('button[aria-label="CONVERSATION.REACTIONS.ADD"]')
      .trigger('click');

    expect(outgoingMessage.get('.absolute.bottom-full').classes()).toContain(
      'end-0'
    );
  });

  it('adds the selected emoji to the message', async () => {
    const wrapper = mountReactions([]);

    await wrapper
      .get('button[aria-label="CONVERSATION.REACTIONS.ADD"]')
      .trigger('click');
    const emojiButton = wrapper
      .findAll('button')
      .find(button => button.text() === '👍');

    expect(emojiButton).toBeDefined();
    await emojiButton.trigger('click');

    expect(store.dispatch).toHaveBeenCalledWith('reactMessage', {
      conversationId: 17,
      messageId: 42,
      emoji: '👍',
    });
  });

  it('closes the emoji picker when clicking outside the reaction controls', async () => {
    const wrapper = mountReactions([]);
    await wrapper
      .get('button[aria-label="CONVERSATION.REACTIONS.ADD"]')
      .trigger('click');

    expect(wrapper.find('.absolute.bottom-full').exists()).toBe(true);

    document.body.dispatchEvent(new MouseEvent('click', { bubbles: true }));
    await wrapper.vm.$nextTick();

    expect(wrapper.find('.absolute.bottom-full').exists()).toBe(false);
  });

  it('replaces the current agent reaction when selecting another emoji', async () => {
    const currentEmoji = '👍';
    const wrapper = mountReactions([
      { emoji: currentEmoji, userId: 9, userName: 'Alex' },
    ]);
    await wrapper
      .get('button[aria-label="CONVERSATION.REACTIONS.ADD"]')
      .trigger('click');
    const replacementButton = wrapper.findAll('.absolute.bottom-full button')[2];
    const replacementEmoji = replacementButton.text();

    await replacementButton.trigger('click');

    expect(store.dispatch).toHaveBeenNthCalledWith(1, 'unreactMessage', {
      conversationId: 17,
      messageId: 42,
      emoji: currentEmoji,
    });
    expect(store.dispatch).toHaveBeenNthCalledWith(2, 'reactMessage', {
      conversationId: 17,
      messageId: 42,
      emoji: replacementEmoji,
    });
  });

  it('removes the current agent reaction when its chip is clicked', async () => {
    const wrapper = mountReactions([
      { emoji: '👍', userId: 9, userName: 'Alex' },
    ]);

    await wrapper.get('button[title="Alex"]').trigger('click');

    expect(store.dispatch).toHaveBeenCalledWith('unreactMessage', {
      conversationId: 17,
      messageId: 42,
      emoji: '👍',
    });
  });
});
