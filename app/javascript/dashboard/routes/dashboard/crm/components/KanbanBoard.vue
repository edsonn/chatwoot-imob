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
      />
    </div>
  </div>
</template>
