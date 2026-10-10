<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useCrmStore } from 'dashboard/stores/crm';
import Button from 'dashboard/components-next/button/Button.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import EmptyStateLayout from 'dashboard/components-next/EmptyStateLayout.vue';
import KanbanBoard from '../components/KanbanBoard.vue';
import KanbanSkeleton from '../components/KanbanSkeleton.vue';

const { t } = useI18n();
const crmStore = useCrmStore();

const pipelines = computed(() => crmStore.getPipelines);
const activePipeline = computed(() => crmStore.getActivePipeline);
const stages = computed(() => crmStore.getStages);
const dealsByStage = computed(() => crmStore.getDealsByStage);
const stageMetrics = computed(() => crmStore.getStageMetrics);
const uiFlags = computed(() => crmStore.getUIFlags);

const isFetchingPipelines = computed(() => uiFlags.value.fetchingPipelines);
const isFetchingDeals = computed(() => uiFlags.value.fetchingDeals);
const isFetching = computed(
  () => isFetchingPipelines.value || isFetchingDeals.value
);

const hasError = computed(() => Boolean(uiFlags.value.error));

const selectedPipelineId = ref(crmStore.activePipelineId);

watch(
  () => crmStore.activePipelineId,
  newId => {
    selectedPipelineId.value = newId;
  }
);

const pipelineOptions = computed(() =>
  pipelines.value.map(p => ({
    label: p.name,
    value: p.id,
  }))
);

const errorMessage = computed(() => {
  const code = uiFlags.value.errorCode;
  if (code === 401 || code === 403) {
    return t('CRM.ERROR_UNAUTHORIZED');
  }
  if (code === 404) {
    return t('CRM.ERROR_NOT_FOUND');
  }
  if (code === 422) {
    return t('CRM.ERROR_UNPROCESSABLE');
  }
  return t('CRM.ERROR_SUBTITLE');
});

const onPipelineChange = newId => {
  if (newId && Number(newId) !== Number(crmStore.activePipelineId)) {
    crmStore.setActivePipeline(Number(newId));
  }
};

const handleReload = () => {
  if (crmStore.activePipelineId) {
    crmStore.fetchDeals(crmStore.activePipelineId);
  } else {
    crmStore.fetchPipelines();
  }
};

const handleRetry = () => {
  handleReload();
};

onMounted(() => {
  crmStore.fetchPipelines();
});
</script>

<template>
  <div class="flex flex-col w-full h-full overflow-hidden bg-n-surface-1">
    <!-- Header -->
    <header
      class="flex items-center justify-between px-6 py-4 border-b border-n-weak bg-n-surface-1 shrink-0 gap-4"
    >
      <div class="flex items-center gap-3 min-w-0">
        <h1 class="text-xl font-semibold text-n-slate-12 truncate">
          {{ t('CRM.HEADER_TITLE') }}
        </h1>
        <span
          v-if="activePipeline && pipelines.length <= 1"
          class="text-sm font-normal text-n-slate-11 truncate hidden sm:inline"
        >
          • {{ activePipeline.name }}
        </span>
      </div>

      <div class="flex items-center gap-3 shrink-0">
        <!-- Pipeline Selector (Only when there are multiple pipelines) -->
        <div v-if="pipelines.length > 1" class="w-56">
          <Select
            v-model="selectedPipelineId"
            :options="pipelineOptions"
            :aria-label="t('CRM.PIPELINE_SELECT_LABEL')"
            @update:model-value="onPipelineChange"
          />
        </div>

        <!-- Reload Action -->
        <Button
          variant="faded"
          color="slate"
          size="sm"
          icon="i-lucide-refresh-cw"
          :is-loading="isFetching"
          :title="t('CRM.RELOAD')"
          @click="handleReload"
        />
      </div>
    </header>

    <!-- Main Content -->
    <main class="flex-1 w-full overflow-hidden p-6 flex flex-col">
      <!-- Loading State -->
      <template v-if="isFetching && stages.length === 0">
        <KanbanSkeleton />
      </template>

      <!-- Error State -->
      <template v-else-if="hasError">
        <div
          class="flex flex-col items-center justify-center m-auto max-w-md p-8 rounded-2xl border border-n-weak bg-n-solid-1 text-center shadow-sm"
        >
          <div
            class="flex items-center justify-center size-12 rounded-full bg-n-ruby-2 text-n-ruby-11 mb-4"
          >
            <span class="i-lucide-alert-triangle size-6" />
          </div>
          <h2 class="text-lg font-semibold text-n-slate-12 mb-2">
            {{ t('CRM.ERROR_TITLE') }}
          </h2>
          <p class="text-sm text-n-slate-11 mb-6 leading-relaxed">
            {{ errorMessage }}
          </p>
          <Button
            variant="solid"
            color="ruby"
            size="sm"
            :label="t('CRM.RETRY')"
            @click="handleRetry"
          />
        </div>
      </template>

      <!-- Empty State: No Pipelines -->
      <template v-else-if="!isFetching && pipelines.length === 0">
        <EmptyStateLayout
          :title="t('CRM.EMPTY_STATE_TITLE')"
          :subtitle="t('CRM.EMPTY_STATE_SUBTITLE')"
          :show-backdrop="false"
        />
      </template>

      <!-- Success State: Kanban Board -->
      <template v-else>
        <KanbanBoard
          :stages="stages"
          :deals-by-stage="dealsByStage"
          :stage-metrics="stageMetrics"
        />
      </template>
    </main>
  </div>
</template>
