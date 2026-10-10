<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';

defineProps({
  isLoading: { type: Boolean, default: false },
});

const emit = defineEmits(['confirm']);

const { t } = useI18n();
const dialogRef = ref(null);

const deal = ref(null);
const finalValue = ref('');
const closedAt = ref('');

const open = dealItem => {
  deal.value = dealItem;
  finalValue.value = dealItem.value != null ? String(dealItem.value) : '';
  // Format current local datetime to YYYY-MM-DDTHH:MM
  const now = new Date();
  const pad = n => String(n).padStart(2, '0');
  closedAt.value = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}T${pad(now.getHours())}:${pad(now.getMinutes())}`;
  dialogRef.value?.open();
};

const handleConfirm = () => {
  if (!deal.value) return;

  emit('confirm', {
    dealId: deal.value.id,
    final_value: finalValue.value !== '' ? Number(finalValue.value) : null,
    closed_at: closedAt.value ? new Date(closedAt.value).toISOString() : null,
  });
};

const close = () => {
  dialogRef.value?.close();
};

const onSuccess = () => {
  deal.value = null;
  finalValue.value = '';
  closedAt.value = '';
  close();
};

defineExpose({ open, close, onSuccess });
</script>

<template>
  <Dialog
    ref="dialogRef"
    width="md"
    :title="t('CRM.DEALS.WON_TITLE')"
    :confirm-button-label="t('CRM.DEALS.WON_CONFIRM')"
    :is-loading="isLoading"
    @confirm="handleConfirm"
  >
    <div v-if="deal" class="flex flex-col gap-4 py-2 text-sm">
      <div class="flex items-center gap-3 p-3 rounded-xl bg-n-teal-2/60 border border-n-teal-4 text-n-teal-11">
        <span class="i-lucide-trophy size-5 shrink-0 text-n-teal-10" />
        <div class="flex flex-col min-w-0 text-xs">
          <span class="font-semibold">{{ t('CRM.DEALS.WON_BANNER_TITLE') }}</span>
          <span class="text-n-teal-11/80">{{ t('CRM.DEALS.WON_BANNER_DESC') }}</span>
        </div>
      </div>

      <div class="flex flex-col gap-1">
        <span class="text-xs font-semibold text-n-slate-11">
          {{ t('CRM.DEALS.TITLE_LABEL') }}:
        </span>
        <span class="font-medium text-n-slate-12">
          {{ deal.title }}
        </span>
      </div>

      <!-- Final Value -->
      <div class="flex flex-col gap-1.5 pt-2 border-t border-n-weak">
        <label class="text-xs font-semibold text-n-slate-12">
          {{ t('CRM.DEALS.FINAL_VALUE_LABEL') }}
        </label>
        <Input
          v-model="finalValue"
          type="number"
          min="0"
          step="0.01"
          :placeholder="t('CRM.DEALS.FINAL_VALUE_PLACEHOLDER')"
          :disabled="isLoading"
        />
        <span class="text-xs text-n-slate-10">
          {{ t('CRM.DEALS.FINAL_VALUE_HELP_TEXT') }}
        </span>
      </div>

      <!-- Closed At -->
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
