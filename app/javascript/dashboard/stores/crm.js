import CrmAPI from 'dashboard/api/crm';
import { createStore } from 'dashboard/store/storeFactory';

const createInitialUIFlags = () => ({
  fetchingPipelines: false,
  fetchingDeals: false,
  error: null,
  errorCode: null,
});

export const useCrmStore = createStore({
  name: 'Crm',
  type: 'pinia',
  API: CrmAPI,

  state: () => ({
    pipelines: [],
    activePipelineId: null,
    deals: [],
    uiFlags: createInitialUIFlags(),
  }),

  getters: {
    getPipelines: state =>
      (state.pipelines || []).slice().sort((a, b) => a.position - b.position),

    getActivePipeline: state => {
      if (!state.pipelines || state.pipelines.length === 0) return null;
      return (
        state.pipelines.find(p => p.id === Number(state.activePipelineId)) ||
        state.pipelines.slice().sort((a, b) => a.position - b.position)[0]
      );
    },

    getStages: state => {
      if (!state.pipelines || state.pipelines.length === 0) return [];
      const pipeline =
        state.pipelines.find(p => p.id === Number(state.activePipelineId)) ||
        state.pipelines.slice().sort((a, b) => a.position - b.position)[0];
      if (!pipeline?.stages) return [];
      return pipeline.stages.slice().sort((a, b) => a.position - b.position);
    },

    getDeals: state =>
      (state.deals || []).slice().sort((a, b) => a.position - b.position),

    getDealsByStage: state => {
      const grouped = {};
      const pipeline =
        state.pipelines.find(p => p.id === Number(state.activePipelineId)) ||
        state.pipelines.slice().sort((a, b) => a.position - b.position)[0];
      const stages = pipeline?.stages || [];

      stages.forEach(stage => {
        grouped[stage.id] = [];
      });

      (state.deals || []).forEach(deal => {
        const stageId = deal.crm_pipeline_stage_id;
        if (grouped[stageId]) {
          grouped[stageId].push(deal);
        } else {
          grouped[stageId] = [deal];
        }
      });

      Object.keys(grouped).forEach(stageId => {
        grouped[stageId].sort((a, b) => (a.position || 0) - (b.position || 0));
      });

      return grouped;
    },

    getStageMetrics: state => {
      const metrics = {};
      const pipeline =
        state.pipelines.find(p => p.id === Number(state.activePipelineId)) ||
        state.pipelines.slice().sort((a, b) => a.position - b.position)[0];
      const stages = pipeline?.stages || [];

      stages.forEach(stage => {
        metrics[stage.id] = { count: 0, totalValue: 0, currency: 'BRL' };
      });

      (state.deals || []).forEach(deal => {
        const stageId = deal.crm_pipeline_stage_id;
        if (!metrics[stageId]) {
          metrics[stageId] = { count: 0, totalValue: 0, currency: 'BRL' };
        }
        metrics[stageId].count += 1;
        metrics[stageId].totalValue += Number(deal.value || 0);
        if (deal.currency) {
          metrics[stageId].currency = deal.currency;
        }
      });

      return metrics;
    },

    getUIFlags: state => state.uiFlags,
  },

  actions: () => ({
    async fetchPipelines() {
      this.setUIFlag({
        fetchingPipelines: true,
        error: null,
        errorCode: null,
      });

      try {
        const response = await CrmAPI.getPipelines();
        const payload = response.data?.payload || [];

        const sortedPipelines = payload
          .map(pipeline => ({
            ...pipeline,
            stages: (pipeline.stages || [])
              .slice()
              .sort((a, b) => a.position - b.position),
          }))
          .sort((a, b) => a.position - b.position);

        this.pipelines = sortedPipelines;

        if (sortedPipelines.length > 0) {
          const currentExists = sortedPipelines.some(
            p => p.id === Number(this.activePipelineId)
          );
          if (!currentExists) {
            const defaultPipeline =
              sortedPipelines.find(p => p.is_default) || sortedPipelines[0];
            this.activePipelineId = defaultPipeline.id;
          }
          await this.fetchDeals(this.activePipelineId);
        } else {
          this.activePipelineId = null;
          this.deals = [];
        }

        return this.pipelines;
      } catch (error) {
        const status = error?.response?.status || 0;
        this.setUIFlag({
          error: error?.message || 'Error',
          errorCode: status,
        });
        return [];
      } finally {
        this.setUIFlag({ fetchingPipelines: false });
      }
    },

    async setActivePipeline(pipelineId) {
      this.activePipelineId = Number(pipelineId);
      await this.fetchDeals(pipelineId);
    },

    async fetchDeals(pipelineId) {
      if (!pipelineId) return [];

      this.setUIFlag({
        fetchingDeals: true,
        error: null,
        errorCode: null,
      });

      try {
        const response = await CrmAPI.getPipelineDeals(pipelineId);
        const payload = response.data?.payload || [];

        this.deals = payload.slice().sort((a, b) => a.position - b.position);
        return this.deals;
      } catch (error) {
        const status = error?.response?.status || 0;
        this.setUIFlag({
          error: error?.message || 'Error',
          errorCode: status,
        });
        return [];
      } finally {
        this.setUIFlag({ fetchingDeals: false });
      }
    },
  }),
});
