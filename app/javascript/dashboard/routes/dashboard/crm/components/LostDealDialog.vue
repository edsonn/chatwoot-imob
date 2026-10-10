<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useCrmStore } from 'dashboard/stores/crm';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

defineProps({
  isLoading: { type: Boolean, default: false },
});

const emit = defineEmits(['confirm']);

const { t } = useI18n();
const crmStore = useCrmStore();
const dialogRef = ref(null);

const deal = ref(null);
const lossReasonId = ref('');
const lossNotes = ref('');
const closedAt = ref('');
const isLoadingReasons = ref(false);

const lossReasons = computed(() => crmStore.getLossReasons);

const lossReasonOptions = computed(() =>
  lossReasons.value.map(r => ({
    label: r.name,
    value: r.id,
  }))
);

const isInvalid = computed(() => !lossReasonId.value);

const open = async dealItem => {
  deal.value = dealItem;
  lossReasonId.value = '';
  lossNotes.value = '';

  const now = new Date();
  const pad = n => String(n).padStart(2, '0');
  closedAt.value = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}T${pad(now.getHours())}:${pad(now.getMinutes())}`;

  dialogRef.value?.open();

  if (!lossReasons.value.length) {
    isLoadingReasons.value = true;
    try {
      await crmStore.fetchLossReasons();
    } finally {
      isLoadingReasons.value = false;
    }
  }
};

const handleConfirm = () => {
  if (isInvalid.value || !deal.value) return;

  emit('confirm', {
    dealId: deal.value.id,
    crm_loss_reason_id: Number(lossReasonId.value),
    loss_notes: lossNotes.value.trim() || null,
    closed_at: closedAt.value ? new Date(closedAt.value).toISOString() : null,
  });
};

const close = () => {
  dialogRef.value?.close();
};

const onSuccess = () => {
  deal.value = null;
  lossReasonId.value = '';
  lossNotes.value = '';
  closedAt.value = '';
  close();
};

defineExpose({ open, close, onSuccess });
</script>

<template>
  <Dialog
    ref="dialogRef"
    width="md"
    type="alert"
    :title="t('CRM.DEALS.LOST_TITLE')"
    :confirm-button-label="t('CRM.DEALS.LOST_CONFIRM')"
    :disable-confirm-button="isInvalid || isLoading"
    :is-loading="isLoading"
    @confirm="handleConfirm"
  >
    <div v-if="deal" class="flex flex-col gap-4 py-2 text-sm">
      <div class="flex flex-col gap-1">
        <span class="text-xs font-semibold text-n-slate-11">
          {{ t('CRM.DEALS.TITLE_LABEL') }}:
        </span>
        <span class="font-medium text-n-slate-12">
          {{ deal.title }}
        </span>
      </div>

      <!-- Loss Reason (Required) -->
      <div class="flex flex-col gap-1.5 pt-2 border-t border-n-weak">
        <div class="flex items-center justify-between">
          <label class="text-xs font-semibold text-n-slate-12">
            {{ t('CRM.DEALS.LOSS_REASON_LABEL') }} *
          </label>
          <Spinner v-if="isLoadingReasons" :size="14" class="text-n-slate-10" />
        </div>
        <Select
          v-model="lossReasonId"
          :options="lossReasonOptions"
          :placeholder="t('CRM.DEALS.SELECT_LOSS_REASON')"
          :disabled="isLoading || isLoadingReasons"
          class="w-full"
        />
      </div>

      <!-- Loss Notes (Optional) -->
      <div class="flex flex-col gap-1.5">
        <label class="text-xs font-semibold text-n-slate-12">
          {{ t('CRM.DEALS.LOSS_NOTES_LABEL') }}
        </label>
        <TextArea
          v-model="lossNotes"
          :placeholder="t('CRM.DEALS.LOSS_NOTES_PLACEHOLDER')"
          :disabled="isLoading"
          class="w-full"
          auto-height
        />
      </div>

      <!-- Closed At (Optional) -->
      <div class="flex flex-col gap-1.5">
        <label class="text-xs font-semibold text-n-slate-12">
          {{ t('CRM.DEALS.CLOSED_AT_LABEL') }}
        </label>
        <Input
          v-model="closedAt"
          type="datetime-local"
          :disabled="isLoading"
        />
      </div>
    </div>
  </Dialog>
</template>
