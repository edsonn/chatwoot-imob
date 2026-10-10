<script setup>
import { computed, reactive, ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useCrmStore } from 'dashboard/stores/crm';
import ContactAPI from 'dashboard/api/contacts';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

defineProps({
  isLoading: { type: Boolean, default: false },
});

const emit = defineEmits(['create', 'update']);

const { t } = useI18n();
const store = useStore();
const crmStore = useCrmStore();
const dialogRef = ref(null);

const currentUserId = computed(() => store.getters.getCurrentUserID);
const isAdmin = computed(() => store.getters.getCurrentRole === 'administrator');
const allAgents = computed(() => store.getters['agents/getAgents'] || []);

const openStages = computed(() => crmStore.getOpenStages);

const stageOptions = computed(() =>
  openStages.value.map(s => ({
    label: s.name,
    value: s.id,
  }))
);

const assigneeOptions = computed(() => {
  if (isAdmin.value) {
    return [
      { label: t('CRM.DEALS.UNASSIGNED'), value: '' },
      ...allAgents.value.map(a => ({
        label: a.name,
        value: a.id,
      })),
    ];
  }
  return [
    { label: t('CRM.DEALS.UNASSIGNED'), value: '' },
    { label: t('CRM.DEALS.ASSIGN_TO_ME'), value: currentUserId.value },
  ];
});

const priorityOptions = computed(() => [
  { label: t('CRM.DEALS.PRIORITY_LOW'), value: 'low' },
  { label: t('CRM.DEALS.PRIORITY_MEDIUM'), value: 'medium' },
  { label: t('CRM.DEALS.PRIORITY_HIGH'), value: 'high' },
  { label: t('CRM.DEALS.PRIORITY_URGENT'), value: 'urgent' },
]);

const businessTypeOptions = computed(() => [
  { label: t('CRM.DEALS.BUSINESS_TYPE_SALE'), value: 'sale' },
  { label: t('CRM.DEALS.BUSINESS_TYPE_RENTAL'), value: 'rental' },
  { label: t('CRM.DEALS.BUSINESS_TYPE_ASSIGNMENT'), value: 'assignment' },
  { label: t('CRM.DEALS.BUSINESS_TYPE_OTHER'), value: 'other' },
]);

const sourceOptions = computed(() => [
  { label: t('CRM.DEALS.SOURCE_META_ADS'), value: 'meta_ads' },
  { label: t('CRM.DEALS.SOURCE_GOOGLE_ADS'), value: 'google_ads' },
  { label: t('CRM.DEALS.SOURCE_WEBSITE'), value: 'website' },
  { label: t('CRM.DEALS.SOURCE_PORTAL'), value: 'portal_imobiliario' },
  { label: t('CRM.DEALS.SOURCE_REFERRAL'), value: 'referral' },
  { label: t('CRM.DEALS.SOURCE_PHONE'), value: 'phone' },
  { label: t('CRM.DEALS.SOURCE_OTHER'), value: 'other' },
]);

const isEditMode = ref(false);
const dealId = ref(null);

const form = reactive({
  title: '',
  crm_pipeline_stage_id: '',
  contact_id: null,
  selectedContact: null,
  value: '',
  currency: 'BRL',
  assignee_id: '',
  priority: 'medium',
  business_type: 'sale',
  source: 'meta_ads',
  next_action: '',
  next_action_at: '',
});

// Contact search state
const contactQuery = ref('');
const contactResults = ref([]);
const isSearchingContacts = ref(false);
const hasSearched = ref(false);
let searchDebounceTimeout = null;

const onContactQueryInput = e => {
  const query = e.target.value;
  contactQuery.value = query;

  if (searchDebounceTimeout) {
    clearTimeout(searchDebounceTimeout);
  }

  if (!query || query.trim().length < 2) {
    contactResults.value = [];
    isSearchingContacts.value = false;
    hasSearched.value = false;
    return;
  }

  isSearchingContacts.value = true;
  hasSearched.value = true;

  searchDebounceTimeout = setTimeout(async () => {
    try {
      const response = await ContactAPI.search(query.trim());
      contactResults.value = response.data?.payload || [];
    } catch {
      contactResults.value = [];
    } finally {
      isSearchingContacts.value = false;
    }
  }, 300);
};

const selectContact = contact => {
  form.contact_id = contact.id;
  form.selectedContact = contact;
  contactQuery.value = '';
  contactResults.value = [];
  hasSearched.value = false;
};

const clearSelectedContact = () => {
  if (isEditMode.value) return; // Immutable on edit
  form.contact_id = null;
  form.selectedContact = null;
};

const isFormInvalid = computed(() => {
  if (!form.title.trim()) return true;
  if (!form.crm_pipeline_stage_id) return true;
  if (!isEditMode.value && !form.contact_id) return true;
  return false;
});

const resetForm = () => {
  form.title = '';
  form.crm_pipeline_stage_id = '';
  form.contact_id = null;
  form.selectedContact = null;
  form.value = '';
  form.currency = 'BRL';
  form.assignee_id = '';
  form.priority = 'medium';
  form.business_type = 'sale';
  form.source = 'meta_ads';
  form.next_action = '';
  form.next_action_at = '';
  contactQuery.value = '';
  contactResults.value = [];
  isSearchingContacts.value = false;
  hasSearched.value = false;
  isEditMode.value = false;
  dealId.value = null;
};

const openCreate = (stageId = null) => {
  resetForm();
  isEditMode.value = false;
  const initialStage = stageId || openStages.value[0]?.id || '';
  form.crm_pipeline_stage_id = initialStage;
  form.assignee_id = isAdmin.value ? '' : currentUserId.value;
  dialogRef.value?.open();
};

const openEdit = deal => {
  resetForm();
  isEditMode.value = true;
  dealId.value = deal.id;
  form.title = deal.title || '';
  form.crm_pipeline_stage_id = deal.crm_pipeline_stage_id || '';
  form.contact_id = deal.contact?.id || null;
  form.selectedContact = deal.contact || null;
  form.value = deal.value != null ? String(deal.value) : '';
  form.currency = deal.currency || 'BRL';
  form.assignee_id = deal.assignee?.id || '';
  form.priority = deal.priority || 'medium';
  form.business_type = deal.business_type || 'sale';
  form.source = deal.source || 'meta_ads';
  form.next_action = deal.next_action || '';
  form.next_action_at = deal.next_action_at ? deal.next_action_at.slice(0, 16) : '';
  dialogRef.value?.open();
};

const handleConfirm = () => {
  if (isFormInvalid.value) return;

  const payload = {
    title: form.title.trim(),
    crm_pipeline_stage_id: Number(form.crm_pipeline_stage_id),
    value: form.value !== '' ? Number(form.value) : null,
    currency: form.currency || 'BRL',
    assignee_id: form.assignee_id ? Number(form.assignee_id) : null,
    priority: form.priority,
    business_type: form.business_type,
    source: form.source,
    next_action: form.next_action ? form.next_action.trim() : null,
    next_action_at: form.next_action_at ? new Date(form.next_action_at).toISOString() : null,
  };

  if (!isEditMode.value) {
    payload.contact_id = Number(form.contact_id);
    emit('create', payload);
  } else {
    emit('update', { id: dealId.value, data: payload });
  }
};

const close = () => {
  dialogRef.value?.close();
};

const onSuccess = () => {
  resetForm();
  close();
};

onMounted(() => {
  if (!allAgents.value.length) {
    store.dispatch('agents/get');
  }
});

defineExpose({ openCreate, openEdit, close, onSuccess });
</script>

<template>
  <Dialog
    ref="dialogRef"
    width="2xl"
    overflow-y-auto
    :title="isEditMode ? t('CRM.DEALS.EDIT_TITLE') : t('CRM.DEALS.CREATE_TITLE')"
    :confirm-button-label="isEditMode ? t('CRM.DEALS.SAVE') : t('CRM.DEALS.CREATE_CONFIRM')"
    :disable-confirm-button="isFormInvalid || isLoading"
    :is-loading="isLoading"
    @confirm="handleConfirm"
    @close="resetForm"
  >
    <div class="flex flex-col gap-5 py-2">
      <!-- Title -->
      <div class="flex flex-col gap-1.5">
        <label class="text-xs font-semibold text-n-slate-12">
          {{ t('CRM.DEALS.TITLE_LABEL') }} *
        </label>
        <Input
          v-model="form.title"
          :placeholder="t('CRM.DEALS.TITLE_PLACEHOLDER')"
          :disabled="isLoading"
          autofocus
        />
      </div>

      <!-- Stage & Value -->
      <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <!-- Stage -->
        <div class="flex flex-col gap-1.5">
          <label class="text-xs font-semibold text-n-slate-12">
            {{ t('CRM.DEALS.STAGE_LABEL') }} *
          </label>
          <Select
            v-model="form.crm_pipeline_stage_id"
            :options="stageOptions"
            :disabled="isLoading"
            class="w-full"
          />
        </div>

        <!-- Value -->
        <div class="flex flex-col gap-1.5">
          <label class="text-xs font-semibold text-n-slate-12">
            {{ t('CRM.DEALS.VALUE_LABEL') }}
          </label>
          <Input
            v-model="form.value"
            type="number"
            min="0"
            step="0.01"
            :placeholder="t('CRM.DEALS.VALUE_PLACEHOLDER')"
            :disabled="isLoading"
          />
        </div>
      </div>

      <!-- Contact Selector (Create: Search | Edit: Readonly) -->
      <div class="flex flex-col gap-1.5">
        <label class="text-xs font-semibold text-n-slate-12">
          {{ t('CRM.DEALS.CONTACT_LABEL') }} *
        </label>

        <!-- Edit Mode: Contact is immutable -->
        <div
          v-if="isEditMode && form.selectedContact"
          class="flex items-center gap-2.5 p-2.5 rounded-lg border border-n-weak bg-n-alpha-1 text-sm text-n-slate-12"
        >
          <Avatar
            :name="form.selectedContact.name || 'Lead'"
            :src="form.selectedContact.thumbnail || ''"
            :size="24"
          />
          <div class="flex flex-col min-w-0">
            <span class="font-medium truncate">{{ form.selectedContact.name }}</span>
            <span v-if="form.selectedContact.email || form.selectedContact.phone_number" class="text-xs text-n-slate-10 truncate">
              {{ form.selectedContact.email || form.selectedContact.phone_number }}
            </span>
          </div>
          <span class="ms-auto text-xs text-n-slate-10 italic">
            {{ t('CRM.DEALS.CONTACT_IMMUTABLE') }}
          </span>
        </div>

        <!-- Create Mode: Selected Contact Badge -->
        <div
          v-else-if="form.selectedContact"
          class="flex items-center justify-between p-2.5 rounded-lg border border-n-weak bg-n-alpha-1 text-sm text-n-slate-12"
        >
          <div class="flex items-center gap-2.5 min-w-0">
            <Avatar
              :name="form.selectedContact.name || 'Lead'"
              :src="form.selectedContact.thumbnail || ''"
              :size="24"
            />
            <div class="flex flex-col min-w-0">
              <span class="font-medium truncate">{{ form.selectedContact.name }}</span>
              <span v-if="form.selectedContact.email || form.selectedContact.phone_number" class="text-xs text-n-slate-10 truncate">
                {{ form.selectedContact.email || form.selectedContact.phone_number }}
              </span>
            </div>
          </div>
          <Button
            variant="ghost"
            color="slate"
            size="xs"
            icon="i-lucide-x"
            @click="clearSelectedContact"
          />
        </div>

        <!-- Create Mode: Search Box -->
        <div v-else class="relative flex flex-col gap-1">
          <div class="relative">
            <input
              type="text"
              :value="contactQuery"
              :placeholder="t('CRM.DEALS.SEARCH_CONTACT_PLACEHOLDER')"
              class="w-full h-9 px-3 pr-8 rounded-lg border-0 outline outline-1 -outline-offset-1 outline-n-weak bg-n-surface-1 text-sm text-n-slate-12 placeholder:text-n-slate-10 focus:outline-n-blue-9"
              @input="onContactQueryInput"
            />
            <div class="absolute inset-y-0 right-2 flex items-center">
              <Spinner v-if="isSearchingContacts" :size="16" class="text-n-slate-10" />
              <span v-else class="i-lucide-search size-4 text-n-slate-10" />
            </div>
          </div>

          <!-- Search Results Dropdown -->
          <div
            v-if="hasSearched && contactQuery.trim().length >= 2"
            class="absolute top-10 inset-x-0 z-50 max-h-48 overflow-y-auto rounded-lg border border-n-weak bg-n-surface-1 shadow-lg py-1"
          >
            <div
              v-if="isSearchingContacts"
              class="p-3 text-center text-xs text-n-slate-10 flex items-center justify-center gap-2"
            >
              <Spinner :size="14" />
              {{ t('CRM.DEALS.SEARCHING_CONTACTS') }}
            </div>
            <div
              v-else-if="contactResults.length === 0"
              class="p-3 text-center text-xs text-n-slate-10"
            >
              {{ t('CRM.DEALS.NO_CONTACTS_FOUND') }}
            </div>
            <template v-else>
              <button
                v-for="contact in contactResults"
                :key="contact.id"
                type="button"
                class="flex items-center gap-2.5 w-full px-3 py-2 text-start text-sm hover:bg-n-alpha-1 transition-colors"
                @click="selectContact(contact)"
              >
                <Avatar
                  :name="contact.name || 'Lead'"
                  :src="contact.thumbnail || ''"
                  :size="20"
                />
                <div class="flex flex-col min-w-0">
                  <span class="font-medium text-n-slate-12 truncate">{{ contact.name }}</span>
                  <span class="text-xs text-n-slate-10 truncate">{{ contact.email || contact.phone_number }}</span>
                </div>
              </button>
            </template>
          </div>
        </div>
      </div>

      <!-- Assignee & Priority -->
      <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <!-- Assignee -->
        <div class="flex flex-col gap-1.5">
          <label class="text-xs font-semibold text-n-slate-12">
            {{ t('CRM.DEALS.ASSIGNEE_LABEL') }}
          </label>
          <Select
            v-model="form.assignee_id"
            :options="assigneeOptions"
            :disabled="isLoading"
            class="w-full"
          />
        </div>

        <!-- Priority -->
        <div class="flex flex-col gap-1.5">
          <label class="text-xs font-semibold text-n-slate-12">
            {{ t('CRM.DEALS.PRIORITY_LABEL') }}
          </label>
          <Select
            v-model="form.priority"
            :options="priorityOptions"
            :disabled="isLoading"
            class="w-full"
          />
        </div>
      </div>

      <!-- Business Type & Source -->
      <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <!-- Business Type -->
        <div class="flex flex-col gap-1.5">
          <label class="text-xs font-semibold text-n-slate-12">
            {{ t('CRM.DEALS.BUSINESS_TYPE_LABEL') }}
          </label>
          <Select
            v-model="form.business_type"
            :options="businessTypeOptions"
            :disabled="isLoading"
            class="w-full"
          />
        </div>

        <!-- Source -->
        <div class="flex flex-col gap-1.5">
          <label class="text-xs font-semibold text-n-slate-12">
            {{ t('CRM.DEALS.SOURCE_LABEL') }}
          </label>
          <Select
            v-model="form.source"
            :options="sourceOptions"
            :disabled="isLoading"
            class="w-full"
          />
        </div>
      </div>

      <!-- Next Action & Next Action Date -->
      <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <!-- Next Action -->
        <div class="flex flex-col gap-1.5">
          <label class="text-xs font-semibold text-n-slate-12">
            {{ t('CRM.DEALS.NEXT_ACTION_LABEL') }}
          </label>
          <Input
            v-model="form.next_action"
            :placeholder="t('CRM.DEALS.NEXT_ACTION_PLACEHOLDER')"
            :disabled="isLoading"
          />
        </div>

        <!-- Next Action Date -->
        <div class="flex flex-col gap-1.5">
          <label class="text-xs font-semibold text-n-slate-12">
            {{ t('CRM.DEALS.NEXT_ACTION_AT_LABEL') }}
          </label>
          <Input
            v-model="form.next_action_at"
            type="datetime-local"
            :disabled="isLoading"
          />
        </div>
      </div>
    </div>
  </Dialog>
</template>
