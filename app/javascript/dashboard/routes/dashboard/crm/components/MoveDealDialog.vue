<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useCrmStore } from 'dashboard/stores/crm';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Select from 'dashboard/components-next/select/Select.vue';

defineProps({
  isLoading: { type: Boolean, default: false },
});

const emit = defineEmits(['confirm']);

const { t } = useI18n();
const crmStore = useCrmStore();
const dialogRef = ref(null);

const deal = ref(null);
const targetStageId = ref('');

const openStages = computed(() => crmStore.getOpenStages);

// List only OPEN stages, excluding the current stage of the deal
const availableStages = computed(() => {
  if (!deal.value) return [];
  return openStages.value.filter(
    stage => stage.id !== deal.value.crm_pipeline_stage_id
  );
});

const stageOptions = computed(() =>
  availableStages.value.map(stage => ({
    label: stage.name,
    value: stage.id,
  }))
);

const isInvalid = computed(() => {
  if (!targetStageId.value) return true;
  if (deal.value && targetStageId.value === deal.value.crm_pipeline_stage_id) {
    return true;
  }
  return false;
});

const open = dealItem => {
  deal.value = dealItem;
  // Pick first available stage by default
  const firstAvailable = openStages.value.find(
    s => s.id !== dealItem.crm_pipeline_stage_id
  );
  targetStageId.value = firstAvailable ? firstAvailable.id : '';
  dialogRef.value?.open();
};

const handleConfirm = () => {
  if (isInvalid.value || !deal.value) return;
  emit('confirm', {
    dealId: deal.value.id,
    crm_pipeline_stage_id: Number(targetStageId.value),
  });
};

const close = () => {
  dialogRef.value?.close();
};

const onSuccess = () => {
  deal.value = null;
  targetStageId.value = '';
  close();
};

defineExpose({ open, close, onSuccess });
</script>

<template>
  <Dialog
    ref="dialogRef"
    width="md"
    :title="t('CRM.DEALS.MOVE_TITLE')"
    :confirm-button-label="t('CRM.DEALS.MOVE_CONFIRM')"
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

      <div class="flex flex-col gap-1">
        <span class="text-xs font-semibold text-n-slate-11">
          {{ t('CRM.DEALS.CURRENT_STAGE_LABEL') }}:
        </span>
        <span class="inline-flex items-center gap-1.5 font-medium text-n-slate-12">
          <span
            class="size-2 rounded-full"
            :style="{ backgroundColor: deal.stage?.color || '#3B82F6' }"
          />
          {{ deal.stage?.name || '-' }}
        </span>
      </div>

      <div class="flex flex-col gap-1.5 pt-2 border-t border-n-weak">
        <label class="text-xs font-semibold text-n-slate-12">
          {{ t('CRM.DEALS.TARGET_STAGE_LABEL') }} *
        </label>
        <Select
          v-model="targetStageId"
          :options="stageOptions"
          :placeholder="t('CRM.DEALS.SELECT_TARGET_STAGE')"
          :disabled="isLoading"
          class="w-full"
        />
        <span class="text-xs text-n-slate-10">
          {{ t('CRM.DEALS.MOVE_HELP_TEXT') }}
        </span>
      </div>
    </div>
  </Dialog>
</template>
