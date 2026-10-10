<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import KanbanCard from './KanbanCard.vue';
import { formatCurrencyAmount } from 'dashboard/constants/billing';

const props = defineProps({
  stage: {
    type: Object,
    required: true,
  },
  deals: {
    type: Array,
    default: () => [],
  },
  metrics: {
    type: Object,
    default: () => ({ count: 0, totalValue: 0, currency: 'BRL' }),
  },
});

const emit = defineEmits(['edit-deal', 'move-deal', 'won-deal', 'lost-deal', 'select-deal']);

const { t } = useI18n();

const formattedTotalValue = computed(() => {
  const amount = Number(props.metrics?.totalValue || 0);
  const currency = props.metrics?.currency || 'BRL';
  try {
    return formatCurrencyAmount(amount, currency);
  } catch {
    return new Intl.NumberFormat('pt-BR', {
      style: 'currency',
      currency: currency.toUpperCase(),
    }).format(amount);
  }
});

const stageColor = computed(() => {
  return props.stage.color || '#3B82F6';
});
</script>

<template>
  <div
    class="flex flex-col w-[300px] shrink-0 rounded-2xl border border-n-weak bg-n-alpha-1/60 dark:bg-n-solid-1/40 p-3 max-h-full"
  >
    <!-- Stage Header -->
    <div class="flex flex-col gap-1.5 pb-3 border-b border-n-weak">
      <div class="flex items-center justify-between gap-2">
        <div class="flex items-center gap-2 min-w-0">
          <span
            class="size-2.5 rounded-full shrink-0"
            :style="{ backgroundColor: stageColor }"
          />
          <h3
            class="text-sm font-semibold text-n-slate-12 truncate"
            :title="stage.name"
          >
            {{ stage.name }}
          </h3>
        </div>
        <span
          class="shrink-0 px-2 py-0.5 rounded-full text-xs font-medium bg-n-alpha-2 text-n-slate-11"
        >
          {{ deals.length }}
        </span>
      </div>

      <!-- Stage Total Value -->
      <div class="text-xs text-n-slate-11 font-medium">
        {{ t('CRM.TOTAL_STAGE_VALUE', { amount: formattedTotalValue }) }}
      </div>
    </div>

    <!-- Deals List -->
    <div
      class="flex-1 flex flex-col gap-2.5 pt-3 overflow-y-auto min-h-[150px] pr-0.5"
    >
      <template v-if="deals.length > 0">
        <KanbanCard
          v-for="deal in deals"
          :key="deal.id"
          :deal="deal"
          @edit="d => emit('edit-deal', d)"
          @move="d => emit('move-deal', d)"
          @won="d => emit('won-deal', d)"
          @lost="d => emit('lost-deal', d)"
          @select="d => emit('select-deal', d)"
        />
      </template>

      <!-- Empty State for Stage -->
      <div
        v-else
        class="flex flex-col items-center justify-center py-10 px-3 text-center rounded-xl border border-dashed border-n-weak/80 text-xs text-n-slate-10"
      >
        <span class="i-lucide-inbox size-5 mb-1.5 opacity-60" />
        {{ t('CRM.EMPTY_STAGE_DEALS') }}
      </div>
    </div>
  </div>
</template>
