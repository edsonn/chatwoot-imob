<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useCrmStore } from 'dashboard/stores/crm';
import { useAlert } from 'dashboard/composables';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';
import Button from 'dashboard/components-next/button/Button.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import EmptyStateLayout from 'dashboard/components-next/EmptyStateLayout.vue';
import KanbanBoard from '../components/KanbanBoard.vue';
import KanbanSkeleton from '../components/KanbanSkeleton.vue';
import KanbanFiltersBar from '../components/KanbanFiltersBar.vue';
import DealFormDialog from '../components/DealFormDialog.vue';
import MoveDealDialog from '../components/MoveDealDialog.vue';
import WonDealDialog from '../components/WonDealDialog.vue';
import LostDealDialog from '../components/LostDealDialog.vue';
import DealDetailsDrawer from '../components/DealDetailsDrawer.vue';

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const crmStore = useCrmStore();

const dealFormDialogRef = ref(null);
const moveDealDialogRef = ref(null);
const wonDealDialogRef = ref(null);
const lostDealDialogRef = ref(null);
const dealDetailsDrawerRef = ref(null);

const pipelines = computed(() => crmStore.getPipelines);
const activePipeline = computed(() => crmStore.getActivePipeline);
const stages = computed(() => crmStore.getStages);
const dealsByStage = computed(() => crmStore.getDealsByStage);
const stageMetrics = computed(() => crmStore.getStageMetrics);
const allDeals = computed(() => crmStore.getDeals);
const uiFlags = computed(() => crmStore.getUIFlags);

const searchQuery = computed(() => crmStore.getSearchQuery);
const assigneeFilter = computed(() => crmStore.getSelectedAssignee);
const priorityFilter = computed(() => crmStore.getSelectedPriority);

const isFetchingPipelines = computed(() => uiFlags.value.fetchingPipelines);
const isFetchingDeals = computed(() => uiFlags.value.fetchingDeals);
const isFetching = computed(
  () => isFetchingPipelines.value || isFetchingDeals.value
);

const isCreatingOrUpdating = computed(
  () => uiFlags.value.creatingDeal || uiFlags.value.updatingDeal
);

const hasError = computed(() => Boolean(uiFlags.value.error));

const selectedPipelineId = ref(crmStore.activePipelineId);

watch(
  () => crmStore.activePipelineId,
  newId => {
    selectedPipelineId.value = newId;
  }
);

// Ao carregar os deals, se houver deal_id na query da URL, abre o drawer correspondente
watch(
  () => [allDeals.value, route.query.deal_id],
  ([deals, dealIdParam]) => {
    if (dealIdParam && deals && deals.length > 0) {
      const targetDeal = deals.find(d => String(d.id) === String(dealIdParam));
      if (targetDeal && !crmStore.getActiveDealDetails) {
        dealDetailsDrawerRef.value?.open(targetDeal);
      }
    }
  },
  { immediate: true }
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

const handleOpenCreateDeal = () => {
  dealFormDialogRef.value?.openCreate();
};

const handleOpenEditDeal = deal => {
  dealFormDialogRef.value?.openEdit(deal);
};

const handleOpenMoveDeal = deal => {
  moveDealDialogRef.value?.open(deal);
};

const handleOpenWonDeal = deal => {
  wonDealDialogRef.value?.open(deal);
};

const handleOpenLostDeal = deal => {
  lostDealDialogRef.value?.open(deal);
};

const handleOpenDealDetails = deal => {
  dealDetailsDrawerRef.value?.open(deal);
  const query = { ...route.query, deal_id: String(deal.id) };
  router.replace({ query });
};

const handleCloseDealDetails = () => {
  const query = { ...route.query };
  delete query.deal_id;
  router.replace({ query });
};

const handleUpdateFilters = ({ q, assignee_id, priority }) => {
  crmStore.setFilters({ q, assignee_id, priority });

  const query = { ...route.query };
  if (q) query.q = q;
  else delete query.q;

  if (assignee_id) query.assignee_id = assignee_id;
  else delete query.assignee_id;

  if (priority) query.priority = priority;
  else delete query.priority;

  router.replace({ query });
};

const handleCreateDeal = async payload => {
  try {
    await crmStore.createDeal(payload);
    useAlert(t('CRM.DEALS.CREATE_SUCCESS'));
    dealFormDialogRef.value?.onSuccess();
  } catch (error) {
    useAlert(parseAPIErrorResponse(error) || t('CRM.DEALS.ERROR_GENERIC'));
  }
};

const handleUpdateDeal = async ({ id, data }) => {
  try {
    await crmStore.updateDeal(id, data);
    useAlert(t('CRM.DEALS.UPDATE_SUCCESS'));
    dealFormDialogRef.value?.onSuccess();
  } catch (error) {
    useAlert(parseAPIErrorResponse(error) || t('CRM.DEALS.ERROR_GENERIC'));
  }
};

const handleConfirmMove = async ({ dealId, crm_pipeline_stage_id }) => {
  try {
    await crmStore.moveDeal(dealId, { crm_pipeline_stage_id });
    useAlert(t('CRM.DEALS.MOVE_SUCCESS'));
    moveDealDialogRef.value?.onSuccess();
  } catch (error) {
    useAlert(parseAPIErrorResponse(error) || t('CRM.DEALS.ERROR_GENERIC'));
  }
};

const handleConfirmWon = async ({ dealId, final_value, closed_at }) => {
  try {
    await crmStore.wonDeal(dealId, { final_value, closed_at });
    useAlert(t('CRM.DEALS.WON_SUCCESS'));
    wonDealDialogRef.value?.onSuccess();
  } catch (error) {
    useAlert(parseAPIErrorResponse(error) || t('CRM.DEALS.ERROR_GENERIC'));
  }
};

const handleConfirmLost = async ({
  dealId,
  crm_loss_reason_id,
  loss_notes,
  closed_at,
}) => {
  try {
    await crmStore.lostDeal(dealId, {
      crm_loss_reason_id,
      loss_notes,
      closed_at,
    });
    useAlert(t('CRM.DEALS.LOST_SUCCESS'));
    lostDealDialogRef.value?.onSuccess();
  } catch (error) {
    useAlert(parseAPIErrorResponse(error) || t('CRM.DEALS.ERROR_GENERIC'));
  }
};

const handleCreateTask = async ({ dealId, payload }) => {
  try {
    await crmStore.createTask(dealId, payload);
    useAlert(t('CRM.TASKS.CREATE_SUCCESS'));
  } catch (error) {
    useAlert(parseAPIErrorResponse(error) || t('CRM.TASKS.ERROR_GENERIC'));
  }
};

const handleToggleTask = async ({ dealId, taskId, completed }) => {
  try {
    await crmStore.updateTask(dealId, taskId, {
      completed_at: completed ? new Date().toISOString() : null,
    });
    useAlert(
      completed
        ? t('CRM.TASKS.COMPLETED_SUCCESS')
        : t('CRM.TASKS.REOPENED_SUCCESS')
    );
  } catch (error) {
    useAlert(parseAPIErrorResponse(error) || t('CRM.TASKS.ERROR_GENERIC'));
  }
};

onMounted(() => {
  // Hidrata filtros a partir da query string da rota
  const { q, assignee_id, priority } = route.query;
  crmStore.setFilters({
    q: q ? String(q) : '',
    assignee_id: assignee_id ? String(assignee_id) : '',
    priority: priority ? String(priority) : '',
  });

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

        <!-- Create Deal Button -->
        <Button
          v-if="activePipeline"
          variant="solid"
          color="blue"
          size="sm"
          icon="i-lucide-plus"
          :label="t('CRM.DEALS.NEW_DEAL')"
          @click="handleOpenCreateDeal"
        />
      </div>
    </header>

    <!-- Main Content -->
    <main class="flex-1 w-full overflow-hidden p-6 flex flex-col">
      <!-- Filters and Search Bar (Active when board is ready) -->
      <KanbanFiltersBar
        v-if="!hasError && pipelines.length > 0 && !isFetching"
        :search-query="searchQuery"
        :assignee-filter="assigneeFilter"
        :priority-filter="priorityFilter"
        @update:filters="handleUpdateFilters"
      />

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
          @edit-deal="handleOpenEditDeal"
          @move-deal="handleOpenMoveDeal"
          @won-deal="handleOpenWonDeal"
          @lost-deal="handleOpenLostDeal"
          @select-deal="handleOpenDealDetails"
        />
      </template>
    </main>

    <!-- Modals -->
    <DealFormDialog
      ref="dealFormDialogRef"
      :is-loading="isCreatingOrUpdating"
      @create="handleCreateDeal"
      @update="handleUpdateDeal"
    />

    <MoveDealDialog
      ref="moveDealDialogRef"
      :is-loading="uiFlags.movingDeal"
      @confirm="handleConfirmMove"
    />

    <WonDealDialog
      ref="wonDealDialogRef"
      :is-loading="uiFlags.winningDeal"
      @confirm="handleConfirmWon"
    />

    <LostDealDialog
      ref="lostDealDialogRef"
      :is-loading="uiFlags.losingDeal"
      @confirm="handleConfirmLost"
    />

    <!-- Deal Details Drawer -->
    <DealDetailsDrawer
      ref="dealDetailsDrawerRef"
      @close="handleCloseDealDetails"
      @create-task="handleCreateTask"
      @toggle-task="handleToggleTask"
    />
  </div>
</template>
