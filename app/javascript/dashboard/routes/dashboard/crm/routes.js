import { frontendURL } from '../../../helper/URLHelper';
import CrmPipelinesIndex from './pages/CrmPipelinesIndex.vue';

const commonMeta = {
  permissions: ['administrator', 'agent'],
};

export const routes = [
  {
    path: frontendURL('accounts/:accountId/crm/pipelines'),
    component: CrmPipelinesIndex,
    meta: commonMeta,
    children: [
      {
        path: '',
        name: 'crm_pipelines_index',
        component: CrmPipelinesIndex,
        meta: commonMeta,
      },
    ],
  },
];
