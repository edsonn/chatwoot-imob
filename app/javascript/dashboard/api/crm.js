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

  createDeal(payload) {
    return axios.post(`${this.url}/deals`, payload);
  }

  updateDeal(id, payload) {
    return axios.patch(`${this.url}/deals/${id}`, payload);
  }

  moveDeal(id, payload) {
    return axios.post(`${this.url}/deals/${id}/move`, payload);
  }

  wonDeal(id, payload) {
    return axios.post(`${this.url}/deals/${id}/won`, payload);
  }

  lostDeal(id, payload) {
    return axios.post(`${this.url}/deals/${id}/lost`, payload);
  }

  getDeal(id) {
    return axios.get(`${this.url}/deals/${id}`);
  }

  createTask(dealId, payload) {
    return axios.post(`${this.url}/deals/${dealId}/tasks`, payload);
  }

  updateTask(dealId, taskId, payload) {
    return axios.patch(`${this.url}/deals/${dealId}/tasks/${taskId}`, payload);
  }

  getLossReasons() {
    return axios.get(`${this.url}/loss_reasons`);
  }
}

export default new CrmAPI();
