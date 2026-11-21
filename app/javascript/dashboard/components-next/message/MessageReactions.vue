<script setup>
import { computed, ref } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Avatar from 'next/avatar/Avatar.vue';

const props = defineProps({
  messageId: { type: Number, required: true },
  conversationId: { type: Number, required: true },
  reactions: { type: Array, default: () => [] },
});

const quickEmojis = ['👍', '❤️', '😂', '😮', '😢', '🙏', '🔥', '🎉'];
const store = useStore();
const { t } = useI18n();
const isPickerOpen = ref(false);
const currentUserId = store.getters.getCurrentUserID;

const groupedReactions = computed(() => {
  const groups = new Map();
  (Array.isArray(props.reactions) ? props.reactions : [])
    .filter(reaction => reaction && typeof reaction.emoji === 'string')
    .forEach(reaction => {
      if (!groups.has(reaction.emoji)) {
        groups.set(reaction.emoji, { emoji: reaction.emoji, users: [] });
      }
      groups.get(reaction.emoji).users.push(reaction);
    });
  return [...groups.values()];
});

const reactionNames = group =>
  group.users
    .map(reaction => reaction.user_name)
    .filter(Boolean)
    .join(', ');

const hasReacted = emoji =>
  (Array.isArray(props.reactions) ? props.reactions : []).some(
    reaction =>
      reaction?.emoji === emoji &&
      Number(reaction.user_id) === Number(currentUserId)
  );

const toggleReaction = async emoji => {
  try {
    await store.dispatch(
      hasReacted(emoji) ? 'unreactMessage' : 'reactMessage',
      {
        conversationId: props.conversationId,
        messageId: props.messageId,
        emoji,
      }
    );
    isPickerOpen.value = false;
  } catch {
    useAlert(t('CONVERSATION.REACTIONS.ERROR'));
  }
};
</script>

<template>
  <div class="relative flex min-h-6 flex-wrap items-center gap-1">
    <button
      v-for="group in groupedReactions"
      :key="group.emoji"
      type="button"
      class="flex items-center gap-1 rounded-full border px-1.5 py-0.5 text-xs transition-colors"
      :class="
        hasReacted(group.emoji)
          ? 'border-n-brand bg-n-brand/10'
          : 'border-n-strong bg-n-alpha-1 hover:bg-n-alpha-2'
      "
      :title="reactionNames(group)"
      :aria-label="`${group.emoji}: ${reactionNames(group)}`"
      @click.stop="toggleReaction(group.emoji)"
    >
      <span>{{ group.emoji }}</span>
      <Avatar
        v-for="reaction in group.users.slice(0, 2)"
        :key="reaction.user_id"
        :name="reaction.user_name || t('CONVERSATION.REACTIONS.UNKNOWN_USER')"
        :src="reaction.user_avatar_url || ''"
        :size="16"
      />
      <span class="max-w-32 truncate font-medium text-n-slate-11">
        {{ reactionNames(group) || t('CONVERSATION.REACTIONS.UNKNOWN_USER') }}
      </span>
    </button>

    <div
      v-if="isPickerOpen"
      class="absolute bottom-full left-0 z-50 mb-1 flex items-center gap-1 rounded-full border border-n-strong bg-white px-2 py-1 shadow-xl dark:bg-n-solid-1"
    >
      <button
        v-for="emoji in quickEmojis"
        :key="emoji"
        type="button"
        class="rounded-full p-1 text-lg transition-transform hover:scale-125 hover:bg-n-alpha-1"
        :aria-label="`${t('CONVERSATION.REACTIONS.ADD')} ${emoji}`"
        @click.stop="toggleReaction(emoji)"
      >
        {{ emoji }}
      </button>
    </div>

    <button
      type="button"
      class="flex size-6 items-center justify-center rounded-full text-sm text-n-slate-11 hover:bg-n-alpha-1"
      :aria-label="t('CONVERSATION.REACTIONS.ADD')"
      :title="t('CONVERSATION.REACTIONS.ADD')"
      :aria-expanded="isPickerOpen"
      @click.stop="isPickerOpen = !isPickerOpen"
    >
      +
    </button>
  </div>
</template>
