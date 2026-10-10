<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useDebounceFn } from '@vueuse/core';
import { useStore } from 'dashboard/composables/store';

import Select from 'dashboard/components-next/select/Select.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  searchQuery: {
    type: String,
    default: '',
  },
  assigneeFilter: {
    type: String,
    default: '',
  },
  priorityFilter: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['update:filters']);

const { t } = useI18n();
const store = useStore();

const currentUserId = computed(() => store.getters.getCurrentUserID);
const isAdmin = computed(() => store.getters.getCurrentRole === 'administrator');
const allAgents = computed(() => store.getters['agents/getAgents'] || []);

const internalQuery = ref(props.searchQuery);
const selectedAssignee = ref(props.assigneeFilter || '');
const selectedPriority = ref(props.priorityFilter || '');

watch(
  () => props.searchQuery,
  newVal => {
    internalQuery.value = newVal;
  }
);

watch(
  () => props.assigneeFilter,
  newVal => {
    selectedAssignee.value = newVal || '';
  }
);

watch(
  () => props.priorityFilter,
  newVal => {
    selectedPriority.value = newVal || '';
  }
);

const emitFilters = () => {
  emit('update:filters', {
    q: internalQuery.value.trim(),
    assignee_id: selectedAssignee.value,
    priority: selectedPriority.value,
  });
};

const debouncedSearch = useDebounceFn(() => {
  emitFilters();
}, 300);

const onQueryInput = e => {
  internalQuery.value = e.target.value;
  debouncedSearch();
};

const onAssigneeChange = val => {
  selectedAssignee.value = val;
  emitFilters();
};

const onPriorityChange = val => {
  selectedPriority.value = val;
  emitFilters();
};

const clearFilters = () => {
  internalQuery.value = '';
  selectedAssignee.value = '';
  selectedPriority.value = '';
  emitFilters();
};

const hasActiveFilters = computed(() => {
  return (
    Boolean(internalQuery.value) ||
    Boolean(selectedAssignee.value) ||
    Boolean(selectedPriority.value)
  );
});

const assigneeOptions = computed(() => {
  if (isAdmin.value) {
    return [
      { label: t('CRM.FILTERS.ALL_ASSIGNEES'), value: '' },
      { label: t('CRM.FILTERS.MY_DEALS'), value: String(currentUserId.value) },
      { label: t('CRM.FILTERS.UNASSIGNED'), value: 'unassigned' },
      ...allAgents.value.map(agent => ({
        label: agent.name,
        value: String(agent.id),
      })),
    ];
  }

  // Para agente: somente Todos, Meus deals e Sem responsável
  return [
    { label: t('CRM.FILTERS.ALL_ASSIGNEES'), value: '' },
    { label: t('CRM.FILTERS.MY_DEALS'), value: String(currentUserId.value) },
    { label: t('CRM.FILTERS.UNASSIGNED'), value: 'unassigned' },
  ];
});

const priorityOptions = computed(() => [
  { label: t('CRM.FILTERS.ALL_PRIORITIES'), value: '' },
  { label: t('CRM.DEALS.PRIORITY_URGENT'), value: 'urgent' },
  { label: t('CRM.DEALS.PRIORITY_HIGH'), value: 'high' },
  { label: t('CRM.DEALS.PRIORITY_MEDIUM'), value: 'medium' },
  { label: t('CRM.DEALS.PRIORITY_LOW'), value: 'low' },
]);
</script>

<template>
  <div class="flex items-center gap-3 flex-wrap pb-3 w-full">
    <!-- Search Bar -->
    <div class="relative flex-1 min-w-[200px] max-w-sm">
      <input
        type="search"
        :value="internalQuery"
        :placeholder="t('CRM.FILTERS.SEARCH_PLACEHOLDER')"
        class="w-full h-8 px-3 ps-8 rounded-lg border-0 outline outline-1 -outline-offset-1 outline-n-weak bg-n-surface-1 text-xs text-n-slate-12 placeholder:text-n-slate-10 focus:outline-n-blue-9"
        @input="onQueryInput"
      />
      <span
        class="absolute inset-y-0 start-2.5 flex items-center pointer-events-none text-n-slate-10"
      >
        <span class="i-lucide-search size-3.5" />
      </span>
    </div>

    <!-- Assignee Filter -->
    <div class="w-44">
      <Select
        v-model="selectedAssignee"
        :options="assigneeOptions"
        :placeholder="t('CRM.FILTERS.ASSIGNEE')"
        class="w-full text-xs"
        @update:model-value="onAssigneeChange"
      />
    </div>

    <!-- Priority Filter -->
    <div class="w-36">
      <Select
        v-model="selectedPriority"
        :options="priorityOptions"
        :placeholder="t('CRM.FILTERS.PRIORITY')"
        class="w-full text-xs"
        @update:model-value="onPriorityChange"
      />
    </div>

    <!-- Clear Filters Button -->
    <Button
      v-if="hasActiveFilters"
      variant="ghost"
      color="slate"
      size="xs"
      icon="i-lucide-x"
      :label="t('CRM.FILTERS.CLEAR')"
      @click="clearFilters"
    />
  </div>
</template>
