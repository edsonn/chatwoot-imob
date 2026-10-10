/* global axios */
import ApiClient from './ApiClient';

class CrmAPI extends ApiClient {
  constructor() {
    super('crm', { accountScoped: true });
  }

  getPipelines() {
    return axios.get(`${this.url}/pipelines`);
  }

  getPipelineDeals(pipelineId) {
    return axios.get(`${this.url}/pipelines/${pipelineId}/deals`);
  }
}

export default new CrmAPI();
