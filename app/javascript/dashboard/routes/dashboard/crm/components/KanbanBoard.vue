<script setup>
import KanbanColumn from './KanbanColumn.vue';

defineProps({
  stages: {
    type: Array,
    required: true,
  },
  dealsByStage: {
    type: Object,
    required: true,
  },
  stageMetrics: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits([
  'edit-deal',
  'move-deal',
  'won-deal',
  'lost-deal',
  'select-deal',
]);
</script>

<template>
  <div class="flex-1 w-full overflow-x-auto pb-4">
    <div class="flex items-start gap-4 h-full min-w-max px-1">
      <KanbanColumn
        v-for="stage in stages"
        :key="stage.id"
        :stage="stage"
        :deals="dealsByStage[stage.id] || []"
        :metrics="stageMetrics[stage.id] || { count: 0, totalValue: 0, currency: 'BRL' }"
        @edit-deal="d => emit('edit-deal', d)"
        @move-deal="d => emit('move-deal', d)"
        @won-deal="d => emit('won-deal', d)"
        @lost-deal="d => emit('lost-deal', d)"
        @select-deal="d => emit('select-deal', d)"
      />
    </div>
  </div>
</template>
