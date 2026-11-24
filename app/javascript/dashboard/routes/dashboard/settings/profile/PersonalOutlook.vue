<script setup>
import { onMounted, ref } from 'vue';
import PersonalOutlookAPI from 'dashboard/api/personalOutlook';
import Button from 'dashboard/components-next/button/Button.vue';
import { useAlert } from 'dashboard/composables';

const connection = ref({ connected: false, email: null });
const messages = ref([]);
const folder = ref('inbox');
const loading = ref(false);

const loadConnection = async () => {
  const { data } = await PersonalOutlookAPI.show();
  connection.value = data;
  if (data.connected) await loadMessages();
};

const loadMessages = async () => {
  loading.value = true;
  try {
    const { data } = await PersonalOutlookAPI.messages(folder.value);
    messages.value = data.messages;
  } catch {
    useAlert('Could not load Outlook messages.');
  } finally {
    loading.value = false;
  }
};

const connect = async () => {
  const { data } = await PersonalOutlookAPI.authorize();
  window.location.assign(data.url);
};

const disconnect = async () => {
  await PersonalOutlookAPI.disconnect();
  connection.value = { connected: false, email: null };
  messages.value = [];
};

const selectFolder = async selectedFolder => {
  folder.value = selectedFolder;
  await loadMessages();
};

onMounted(loadConnection);
</script>

<template>
  <div class="flex flex-col gap-4">
    <div class="flex items-center justify-between gap-3">
      <div>
        <p v-if="connection.connected" class="text-sm text-n-slate-12">
          {{ connection.email }}
        </p>
        <p v-else class="text-sm text-n-slate-11">
          {{ $t('PROFILE_SETTINGS.OUTLOOK.DISCONNECTED') }}
        </p>
      </div>
      <div class="flex gap-2">
        <Button
          v-if="!connection.connected"
          variant="solid"
          color="blue"
          type="button"
          @click="connect"
        >
          {{ $t('PROFILE_SETTINGS.OUTLOOK.CONNECT') }}
        </Button>
        <Button
          v-else
          variant="outline"
          type="button"
          @click="disconnect"
        >
          {{ $t('PROFILE_SETTINGS.OUTLOOK.DISCONNECT') }}
        </Button>
      </div>
    </div>

    <template v-if="connection.connected">
      <div class="flex gap-2">
        <Button variant="outline" size="sm" @click="selectFolder('inbox')">
          {{ $t('PROFILE_SETTINGS.OUTLOOK.INBOX') }}
        </Button>
        <Button variant="outline" size="sm" @click="selectFolder('sent')">
          {{ $t('PROFILE_SETTINGS.OUTLOOK.SENT') }}
        </Button>
      </div>
      <p v-if="loading" class="text-sm text-n-slate-11">
        {{ $t('PROFILE_SETTINGS.OUTLOOK.LOADING') }}
      </p>
      <ul v-else class="flex flex-col divide-y divide-n-weak">
        <li v-for="message in messages" :key="message.id" class="py-3">
          <p class="font-medium text-n-slate-12">{{ message.subject }}</p>
          <p class="text-sm text-n-slate-11">{{ message.from }} · {{ message.date }}</p>
          <p class="mt-2 whitespace-pre-wrap text-sm text-n-slate-11">{{ message.body }}</p>
        </li>
      </ul>
    </template>
  </div>
</template>
