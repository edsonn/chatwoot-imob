import CrmAPI from 'dashboard/api/crm';
import { createStore } from 'dashboard/store/storeFactory';

const createInitialUIFlags = () => ({
  fetchingPipelines: false,
  fetchingDeals: false,
  creatingDeal: false,
  updatingDeal: false,
  movingDeal: false,
  winningDeal: false,
  losingDeal: false,
  fetchingLossReasons: false,
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
    lossReasons: [],
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

    getOpenStages: state => {
      if (!state.pipelines || state.pipelines.length === 0) return [];
      const pipeline =
        state.pipelines.find(p => p.id === Number(state.activePipelineId)) ||
        state.pipelines.slice().sort((a, b) => a.position - b.position)[0];
      if (!pipeline?.stages) return [];
      return pipeline.stages
        .filter(s => s.stage_type === 'open')
        .slice()
        .sort((a, b) => a.position - b.position);
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

    getLossReasons: state => state.lossReasons,

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

    async fetchLossReasons() {
      if (this.lossReasons && this.lossReasons.length > 0) {
        return this.lossReasons;
      }

      this.setUIFlag({ fetchingLossReasons: true });
      try {
        const response = await CrmAPI.getLossReasons();
        this.lossReasons = response.data?.payload || [];
        return this.lossReasons;
      } catch (error) {
        return [];
      } finally {
        this.setUIFlag({ fetchingLossReasons: false });
      }
    },

    async createDeal(payload) {
      this.setUIFlag({ creatingDeal: true });
      try {
        const response = await CrmAPI.createDeal(payload);
        const createdDeal = response.data?.payload || response.data;
        if (createdDeal && createdDeal.id && createdDeal.crm_pipeline_stage_id) {
          const exists = this.deals.some(d => d.id === createdDeal.id);
          if (!exists) {
            this.deals.push(createdDeal);
          }
        } else if (this.activePipelineId) {
          await this.fetchDeals(this.activePipelineId);
        }
        return createdDeal;
      } finally {
        this.setUIFlag({ creatingDeal: false });
      }
    },

    async updateDeal(id, payload) {
      this.setUIFlag({ updatingDeal: true });
      try {
        const response = await CrmAPI.updateDeal(id, payload);
        const updatedDeal = response.data?.payload || response.data;
        if (updatedDeal && updatedDeal.id && updatedDeal.crm_pipeline_stage_id) {
          const index = this.deals.findIndex(d => d.id === updatedDeal.id);
          if (index !== -1) {
            this.deals[index] = updatedDeal;
          } else {
            this.deals.push(updatedDeal);
          }
        } else if (this.activePipelineId) {
          await this.fetchDeals(this.activePipelineId);
        }
        return updatedDeal;
      } finally {
        this.setUIFlag({ updatingDeal: false });
      }
    },

    async moveDeal(id, payload) {
      this.setUIFlag({ movingDeal: true });
      try {
        const response = await CrmAPI.moveDeal(id, payload);
        const movedDeal = response.data?.payload || response.data;
        if (movedDeal && movedDeal.id && movedDeal.crm_pipeline_stage_id) {
          const index = this.deals.findIndex(d => d.id === movedDeal.id);
          if (index !== -1) {
            this.deals[index] = movedDeal;
          } else {
            this.deals.push(movedDeal);
          }
        } else if (this.activePipelineId) {
          await this.fetchDeals(this.activePipelineId);
        }
        return movedDeal;
      } finally {
        this.setUIFlag({ movingDeal: false });
      }
    },

    async wonDeal(id, payload) {
      this.setUIFlag({ winningDeal: true });
      try {
        const response = await CrmAPI.wonDeal(id, payload);
        const wonDeal = response.data?.payload || response.data;
        if (wonDeal && wonDeal.id && wonDeal.crm_pipeline_stage_id) {
          const index = this.deals.findIndex(d => d.id === wonDeal.id);
          if (index !== -1) {
            this.deals[index] = wonDeal;
          } else {
            this.deals.push(wonDeal);
          }
        } else {
          if (this.activePipelineId) {
            await this.fetchDeals(this.activePipelineId);
          }
          throw new Error('Invalid stage returned by API after winning deal');
        }
        return wonDeal;
      } finally {
        this.setUIFlag({ winningDeal: false });
      }
    },

    async lostDeal(id, payload) {
      this.setUIFlag({ losingDeal: true });
      try {
        const response = await CrmAPI.lostDeal(id, payload);
        const lostDeal = response.data?.payload || response.data;
        if (lostDeal && lostDeal.id && lostDeal.crm_pipeline_stage_id) {
          const index = this.deals.findIndex(d => d.id === lostDeal.id);
          if (index !== -1) {
            this.deals[index] = lostDeal;
          } else {
            this.deals.push(lostDeal);
          }
        } else {
          if (this.activePipelineId) {
            await this.fetchDeals(this.activePipelineId);
          }
          throw new Error('Invalid stage returned by API after losing deal');
        }
        return lostDeal;
      } finally {
        this.setUIFlag({ losingDeal: false });
      }
    },
  }),
});
