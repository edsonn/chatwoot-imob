<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useStore } from 'dashboard/composables/store';
import { useCrmStore } from 'dashboard/stores/crm';
import { formatCurrencyAmount } from 'dashboard/constants/billing';

import SidePanel from 'dashboard/components-next/side-panel/SidePanel.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import DealTasksList from './DealTasksList.vue';
import DealActivityTimeline from './DealActivityTimeline.vue';

const emit = defineEmits(['close', 'create-task', 'toggle-task']);

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const store = useStore();
const crmStore = useCrmStore();

const sidePanelRef = ref(null);
const activeTab = ref('overview'); // 'overview' | 'tasks' | 'history'

const currentUserId = computed(() => store.getters.getCurrentUserID);
const isAdmin = computed(() => store.getters.getCurrentRole === 'administrator');

const deal = computed(() => crmStore.getActiveDealDetails);
const uiFlags = computed(() => crmStore.getUIFlags);
const isFetchingDetails = computed(() => uiFlags.value.fetchingDealDetails);
const isCreatingTask = computed(() => uiFlags.value.creatingTask);

const canOperate = computed(() => {
  if (isAdmin.value) return true;
  if (!deal.value) return false;
  const assigneeId = deal.value.assignee?.id;
  return !assigneeId || assigneeId === currentUserId.value;
});

const formattedValue = computed(() => {
  if (!deal.value) return '';
  const val = Number(deal.value.value || 0);
  const currency = deal.value.currency || 'BRL';
  try {
    return formatCurrencyAmount(val, currency);
  } catch {
    return new Intl.NumberFormat('pt-BR', {
      style: 'currency',
      currency: currency.toUpperCase(),
    }).format(val);
  }
});

const formattedFinalValue = computed(() => {
  if (!deal.value || deal.value.final_value == null) return null;
  const val = Number(deal.value.final_value);
  const currency = deal.value.currency || 'BRL';
  try {
    return formatCurrencyAmount(val, currency);
  } catch {
    return new Intl.NumberFormat('pt-BR', {
      style: 'currency',
      currency: currency.toUpperCase(),
    }).format(val);
  }
});

const priorityConfig = computed(() => {
  if (!deal.value) return {};
  const map = {
    urgent: {
      label: t('CRM.DEALS.PRIORITY_URGENT'),
      classes: 'bg-n-ruby-2 text-n-ruby-11 outline-n-ruby-4',
    },
    high: {
      label: t('CRM.DEALS.PRIORITY_HIGH'),
      classes: 'bg-n-amber-2 text-n-amber-11 outline-n-amber-4',
    },
    medium: {
      label: t('CRM.DEALS.PRIORITY_MEDIUM'),
      classes: 'bg-n-blue-2 text-n-blue-11 outline-n-blue-4',
    },
    low: {
      label: t('CRM.DEALS.PRIORITY_LOW'),
      classes: 'bg-n-slate-3 text-n-slate-11 outline-n-slate-5',
    },
  };
  return map[deal.value.priority] || map.medium;
});

const statusBadge = computed(() => {
  if (!deal.value) return {};
  const map = {
    won: {
      label: t('CRM.STATUS.WON'),
      classes: 'bg-n-teal-2 text-n-teal-11 outline-n-teal-4',
    },
    lost: {
      label: t('CRM.STATUS.LOST'),
      classes: 'bg-n-ruby-2 text-n-ruby-11 outline-n-ruby-4',
    },
    open: {
      label: t('CRM.STATUS.OPEN'),
      classes: 'bg-n-blue-2 text-n-blue-11 outline-n-blue-4',
    },
  };
  return map[deal.value.status] || map.open;
});

const formatDateTime = dateStr => {
  if (!dateStr) return '';
  try {
    const date = new Date(dateStr);
    return new Intl.DateTimeFormat('pt-BR', {
      dateStyle: 'short',
      timeStyle: 'short',
    }).format(date);
  } catch {
    return dateStr;
  }
};

const open = dealData => {
  activeTab.value = 'overview';
  crmStore.setActiveDealDetails(dealData);
  sidePanelRef.value?.open();

  // Carrega os detalhes completos em segundo plano
  if (dealData?.id) {
    crmStore.fetchDealDetails(dealData.id).catch(() => {});
  }
};

const close = () => {
  sidePanelRef.value?.close();
};

const onPanelClose = () => {
  crmStore.clearActiveDealDetails();
  emit('close');
};

const handleOpenConversation = () => {
  if (!deal.value?.conversation?.id) return;
  router.push({
    name: 'inbox_conversation',
    params: {
      accountId: route.params.accountId,
      conversation_id: deal.value.conversation.id,
    },
  });
};

const handleCreateTask = payload => {
  if (!deal.value?.id) return;
  emit('create-task', { dealId: deal.value.id, payload });
};

const handleToggleTask = ({ taskId, completed }) => {
  if (!deal.value?.id) return;
  emit('toggle-task', { dealId: deal.value.id, taskId, completed });
};

defineExpose({ open, close });
</script>

<template>
  <SidePanel
    ref="sidePanelRef"
    width="2xl"
    :title="deal?.title || t('CRM.DRAWER.TITLE')"
    @close="onPanelClose"
  >
    <template #header>
      <div class="flex flex-col gap-1 min-w-0 flex-1">
        <div class="flex items-center gap-2 flex-wrap">
          <span
            v-if="deal?.status"
            class="px-2 py-0.5 rounded text-[11px] font-semibold outline outline-1 -outline-offset-1"
            :class="statusBadge.classes"
          >
            {{ statusBadge.label }}
          </span>

          <span
            v-if="deal?.stage"
            class="inline-flex items-center gap-1.5 px-2 py-0.5 rounded text-[11px] font-medium bg-n-alpha-1 text-n-slate-12"
          >
            <span
              class="size-2 rounded-full"
              :style="{ backgroundColor: deal.stage.color || '#3B82F6' }"
            />
            {{ deal.stage.name }}
          </span>

          <span
            v-if="isFetchingDetails"
            class="inline-flex items-center gap-1 text-[11px] text-n-slate-10 ms-auto"
          >
            <Spinner :size="12" />
            <span>{{ t('CRM.DRAWER.SYNCING') }}</span>
          </span>
        </div>

        <h3 class="text-base font-semibold text-n-slate-12 truncate mt-1">
          {{ deal?.title }}
        </h3>
      </div>
    </template>

    <div v-if="deal" class="flex flex-col gap-5">
      <!-- Lost Banner -->
      <div
        v-if="deal.status === 'lost'"
        class="flex flex-col gap-1.5 p-3 rounded-xl bg-n-ruby-2/50 border border-n-ruby-4 text-xs text-n-ruby-11"
      >
        <div class="flex items-center gap-1.5 font-semibold">
          <span class="i-lucide-alert-circle size-4" />
          <span>{{ t('CRM.DEALS.LOST_BANNER_TITLE') }}</span>
        </div>
        <div v-if="deal.loss_reason?.name" class="ps-5">
          <span class="font-medium">{{ t('CRM.DEALS.LOSS_REASON_LABEL') }}: </span>
          <span>{{ deal.loss_reason.name }}</span>
        </div>
        <div v-if="deal.loss_notes" class="ps-5 text-n-ruby-11/90">
          <span class="font-medium">{{ t('CRM.DEALS.LOSS_NOTES_LABEL') }}: </span>
          <span>{{ deal.loss_notes }}</span>
        </div>
      </div>

      <!-- Navigation Tabs -->
      <div class="flex items-center gap-1 border-b border-n-weak pb-1">
        <button
          type="button"
          class="px-3 py-1.5 rounded-lg text-xs font-medium transition-colors"
          :class="activeTab === 'overview' ? 'bg-n-alpha-2 text-n-slate-12 font-semibold' : 'text-n-slate-11 hover:text-n-slate-12'"
          @click="activeTab = 'overview'"
        >
          {{ t('CRM.DRAWER.TAB_OVERVIEW') }}
        </button>
        <button
          type="button"
          class="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-medium transition-colors"
          :class="activeTab === 'tasks' ? 'bg-n-alpha-2 text-n-slate-12 font-semibold' : 'text-n-slate-11 hover:text-n-slate-12'"
          @click="activeTab = 'tasks'"
        >
          <span>{{ t('CRM.DRAWER.TAB_TASKS') }}</span>
          <span
            v-if="deal.tasks && deal.tasks.filter(t => !t.completed_at).length > 0"
            class="px-1.5 py-0.2 rounded-full text-[10px] font-semibold bg-n-blue-2 text-n-blue-11"
          >
            {{ deal.tasks.filter(t => !t.completed_at).length }}
          </span>
        </button>
        <button
          type="button"
          class="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-medium transition-colors"
          :class="activeTab === 'history' ? 'bg-n-alpha-2 text-n-slate-12 font-semibold' : 'text-n-slate-11 hover:text-n-slate-12'"
          @click="activeTab = 'history'"
        >
          <span>{{ t('CRM.DRAWER.TAB_HISTORY') }}</span>
          <span
            v-if="deal.activities && deal.activities.length > 0"
            class="px-1.5 py-0.2 rounded-full text-[10px] bg-n-alpha-2 text-n-slate-10"
          >
            {{ deal.activities.length }}
          </span>
        </button>
      </div>

      <!-- Tab Content: Overview -->
      <div v-if="activeTab === 'overview'" class="flex flex-col gap-5">
        <!-- Value Cards -->
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <div class="flex flex-col p-3 rounded-xl border border-n-weak bg-n-solid-1">
            <span class="text-xs text-n-slate-10 font-medium">
              {{ t('CRM.DEALS.VALUE_LABEL') }}
            </span>
            <span class="text-lg font-semibold text-n-slate-12 mt-0.5">
              {{ formattedValue }}
            </span>
          </div>

          <div
            v-if="formattedFinalValue"
            class="flex flex-col p-3 rounded-xl border border-n-teal-4 bg-n-teal-2/30"
          >
            <span class="text-xs text-n-teal-11 font-medium">
              {{ t('CRM.DEALS.FINAL_VALUE_LABEL') }}
            </span>
            <span class="text-lg font-semibold text-n-teal-12 mt-0.5">
              {{ formattedFinalValue }}
            </span>
          </div>
        </div>

        <!-- Contact Section -->
        <div class="flex flex-col gap-2 p-3.5 rounded-xl border border-n-weak bg-n-solid-1">
          <span class="text-xs font-semibold text-n-slate-11 uppercase tracking-wider">
            {{ t('CRM.DEALS.CONTACT_LABEL') }}
          </span>
          <div v-if="deal.contact" class="flex items-center justify-between gap-3">
            <div class="flex items-center gap-2.5 min-w-0">
              <Avatar
                :name="deal.contact.name || 'Lead'"
                :src="deal.contact.thumbnail || ''"
                :size="32"
              />
              <div class="flex flex-col min-w-0 text-xs">
                <span class="font-semibold text-n-slate-12 truncate">{{ deal.contact.name }}</span>
                <span v-if="deal.contact.phone_number" class="text-n-slate-10 truncate">
                  {{ deal.contact.phone_number }}
                </span>
                <span v-if="deal.contact.email" class="text-n-slate-10 truncate">
                  {{ deal.contact.email }}
                </span>
              </div>
            </div>

            <!-- Open Conversation Button -->
            <Button
              v-if="deal.conversation?.id"
              variant="faded"
              color="blue"
              size="xs"
              icon="i-lucide-message-circle"
              :label="t('CRM.DRAWER.OPEN_CONVERSATION')"
              @click="handleOpenConversation"
            />
          </div>
          <div v-else class="text-xs text-n-slate-10 italic">
            {{ t('CRM.NO_CONTACT') }}
          </div>
        </div>

        <!-- Commercial Details Grid -->
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs">
          <!-- Assignee -->
          <div class="flex flex-col p-3 rounded-xl border border-n-weak bg-n-solid-1 gap-1">
            <span class="text-n-slate-10 font-medium">
              {{ t('CRM.DEALS.ASSIGNEE_LABEL') }}
            </span>
            <div class="flex items-center gap-2 mt-0.5">
              <Avatar
                v-if="deal.assignee"
                :name="deal.assignee.name"
                :src="deal.assignee.avatar_url || ''"
                :size="18"
              />
              <span class="font-medium text-n-slate-12">
                {{ deal.assignee?.name || t('CRM.UNASSIGNED') }}
              </span>
            </div>
          </div>

          <!-- Priority -->
          <div class="flex flex-col p-3 rounded-xl border border-n-weak bg-n-solid-1 gap-1">
            <span class="text-n-slate-10 font-medium">
              {{ t('CRM.DEALS.PRIORITY_LABEL') }}
            </span>
            <div>
              <span
                class="inline-flex items-center px-1.5 py-0.5 rounded text-[11px] font-semibold outline outline-1 -outline-offset-1 mt-0.5"
                :class="priorityConfig.classes"
              >
                {{ priorityConfig.label }}
              </span>
            </div>
          </div>

          <!-- Business Type -->
          <div class="flex flex-col p-3 rounded-xl border border-n-weak bg-n-solid-1 gap-1">
            <span class="text-n-slate-10 font-medium">
              {{ t('CRM.DEALS.BUSINESS_TYPE_LABEL') }}
            </span>
            <span class="font-medium text-n-slate-12 capitalize mt-0.5">
              {{ t(`CRM.DEALS.BUSINESS_TYPE_${(deal.business_type || 'other').toUpperCase()}`) }}
            </span>
          </div>

          <!-- Source -->
          <div class="flex flex-col p-3 rounded-xl border border-n-weak bg-n-solid-1 gap-1">
            <span class="text-n-slate-10 font-medium">
              {{ t('CRM.DEALS.SOURCE_LABEL') }}
            </span>
            <span class="font-medium text-n-slate-12 capitalize mt-0.5">
              {{ t(`CRM.DEALS.SOURCE_${(deal.source || 'other').toUpperCase()}`) }}
            </span>
          </div>
        </div>

        <!-- Next Action Section -->
        <div
          v-if="deal.next_action || deal.next_action_at"
          class="flex flex-col p-3.5 rounded-xl border border-n-weak bg-n-solid-1 gap-1 text-xs"
        >
          <span class="font-semibold text-n-slate-11 uppercase tracking-wider">
            {{ t('CRM.DEALS.NEXT_ACTION_LABEL') }}
          </span>
          <p v-if="deal.next_action" class="text-sm font-medium text-n-slate-12 mt-1">
            {{ deal.next_action }}
          </p>
          <span v-if="deal.next_action_at" class="inline-flex items-center gap-1.5 text-n-slate-10 mt-1">
            <span class="i-lucide-calendar size-3.5" />
            <span>{{ t('CRM.DEALS.NEXT_ACTION_AT_LABEL') }}: {{ formatDateTime(deal.next_action_at) }}</span>
          </span>
        </div>
      </div>

      <!-- Tab Content: Tasks -->
      <div v-else-if="activeTab === 'tasks'">
        <DealTasksList
          :deal="deal"
          :can-operate="canOperate"
          :is-creating="isCreatingTask"
          @create-task="handleCreateTask"
          @toggle-task="handleToggleTask"
        />
      </div>

      <!-- Tab Content: History -->
      <div v-else-if="activeTab === 'history'">
        <DealActivityTimeline :activities="deal.activities || []" />
      </div>
    </div>
  </SidePanel>
</template>
