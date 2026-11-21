import { mount } from '@vue/test-utils';
import MessageReactions from '../MessageReactions.vue';

const store = vi.hoisted(() => ({
  dispatch: vi.fn(),
  getters: { getCurrentUserID: 9 },
}));

vi.mock('vuex', () => ({ useStore: () => store }));
vi.mock('vue-i18n', () => ({ useI18n: () => ({ t: key => key }) }));
vi.mock('dashboard/composables', () => ({ useAlert: vi.fn() }));

const mountReactions = reactions =>
  mount(MessageReactions, {
    props: { messageId: 42, conversationId: 17, reactions },
    global: {
      stubs: {
        Avatar: {
          props: ['name', 'src', 'size'],
          template: '<span class="avatar" />',
        },
      },
    },
  });

describe('MessageReactions', () => {
  beforeEach(() => {
    store.dispatch.mockReset();
  });

  it('shows who reacted beside the emoji', () => {
    const wrapper = mountReactions([
      { emoji: '👍', user_id: 4, user_name: 'Ana' },
      { emoji: '👍', user_id: 5, user_name: 'Bruno' },
    ]);

    expect(wrapper.text()).toContain('Ana, Bruno');
  });

  it('adds the selected emoji to the message', async () => {
    const wrapper = mountReactions([]);

    await wrapper
      .get('button[aria-label="CONVERSATION.REACTIONS.ADD"]')
      .trigger('click');
    await wrapper
      .get('button[aria-label="CONVERSATION.REACTIONS.ADD 👍"]')
      .trigger('click');

    expect(store.dispatch).toHaveBeenCalledWith('reactMessage', {
      conversationId: 17,
      messageId: 42,
      emoji: '👍',
    });
  });

  it('removes the current agent reaction when its chip is clicked', async () => {
    const wrapper = mountReactions([
      { emoji: '👍', user_id: 9, user_name: 'Alex' },
    ]);

    await wrapper.get('button[title="Alex"]').trigger('click');

    expect(store.dispatch).toHaveBeenCalledWith('unreactMessage', {
      conversationId: 17,
      messageId: 42,
      emoji: '👍',
    });
  });
});
