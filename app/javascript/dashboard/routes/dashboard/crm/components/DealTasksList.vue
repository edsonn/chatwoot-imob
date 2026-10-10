<script setup>
import { computed, reactive, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';

const props = defineProps({
  deal: {
    type: Object,
    required: true,
  },
  canOperate: {
    type: Boolean,
    default: true,
  },
  isCreating: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['create-task', 'toggle-task']);

const { t } = useI18n();
const store = useStore();

const showAddForm = ref(false);

const currentUserId = computed(() => store.getters.getCurrentUserID);
const isAdmin = computed(() => store.getters.getCurrentRole === 'administrator');
const allAgents = computed(() => store.getters['agents/getAgents'] || []);

const tasks = computed(() => props.deal?.tasks || []);

const now = new Date();

const pendingTasks = computed(() =>
  tasks.value
    .filter(t => !t.completed_at)
    .sort((a, b) => new Date(a.due_date) - new Date(b.due_date))
);

const completedTasks = computed(() =>
  tasks.value
    .filter(t => Boolean(t.completed_at))
    .sort((a, b) => new Date(b.completed_at) - new Date(a.completed_at))
);

const isOverdue = dueDateStr => {
  if (!dueDateStr) return false;
  return new Date(dueDateStr) < now;
};

const formatDateTime = dateStr => {
  if (!dateStr) return '';
  try {
    const date = new Date(dateStr);
    return new Intl.DateTimeFormat('pt-BR', {
      dateStyle: 'short',
      timeStyle: 'short',
    }).format(date);
  } catch {
    return dateStr;
  }
};

const taskTypeOptions = computed(() => [
  { label: t('CRM.TASKS.TYPE_VISIT'), value: 'visit' },
  { label: t('CRM.TASKS.TYPE_CALL'), value: 'call' },
  { label: t('CRM.TASKS.TYPE_CONTRACT'), value: 'contract' },
  { label: t('CRM.TASKS.TYPE_FOLLOW_UP'), value: 'follow_up' },
]);

const assigneeOptions = computed(() => {
  if (isAdmin.value) {
    return allAgents.value.map(a => ({
      label: a.name,
      value: a.id,
    }));
  }
  return [{ label: t('CRM.TASKS.ASSIGN_TO_ME'), value: currentUserId.value }];
});

const form = reactive({
  title: '',
  task_type: 'visit',
  due_date: '',
  user_id: '',
});

const resetForm = () => {
  form.title = '';
  form.task_type = 'visit';
  form.due_date = '';
  form.user_id = isAdmin.value ? currentUserId.value : currentUserId.value;
  showAddForm.value = false;
};

const openCreateForm = () => {
  form.title = '';
  form.task_type = 'visit';
  form.user_id = currentUserId.value;
  // Sugere amanhã no mesmo horário
  const tomorrow = new Date();
  tomorrow.setDate(tomorrow.getDate() + 1);
  const pad = n => String(n).padStart(2, '0');
  form.due_date = `${tomorrow.getFullYear()}-${pad(tomorrow.getMonth() + 1)}-${pad(tomorrow.getDate())}T${pad(tomorrow.getHours())}:${pad(tomorrow.getMinutes())}`;
  showAddForm.value = true;
};

const isFormInvalid = computed(() => {
  if (!form.title.trim()) return true;
  if (!form.task_type) return true;
  if (!form.due_date) return true;
  return false;
});

const handleCreate = () => {
  if (isFormInvalid.value) return;

  const payload = {
    title: form.title.trim(),
    task_type: form.task_type,
    due_date: new Date(form.due_date).toISOString(),
    user_id: form.user_id ? Number(form.user_id) : currentUserId.value,
  };

  emit('create-task', payload);
  resetForm();
};

const handleToggle = (task, isChecked) => {
  emit('toggle-task', {
    taskId: task.id,
    completed: isChecked,
  });
};

const getTaskTypeIcon = type => {
  const map = {
    visit: 'i-lucide-home',
    call: 'i-lucide-phone',
    contract: 'i-lucide-file-text',
    follow_up: 'i-lucide-calendar',
  };
  return map[type] || 'i-lucide-check-square';
};
</script>

<template>
  <div class="flex flex-col gap-5 py-2">
    <!-- Header with Add Task Button -->
    <div class="flex items-center justify-between">
      <h4 class="text-xs font-semibold uppercase tracking-wider text-n-slate-11">
        {{ t('CRM.TASKS.TITLE') }}
      </h4>
      <Button
        v-if="canOperate && !showAddForm"
        variant="ghost"
        color="blue"
        size="xs"
        icon="i-lucide-plus"
        :label="t('CRM.TASKS.ADD_TASK')"
        @click="openCreateForm"
      />
    </div>

    <!-- Compact New Task Form -->
    <div
      v-if="showAddForm && canOperate"
      class="flex flex-col gap-3 p-3.5 rounded-xl border border-n-blue-4 bg-n-blue-2/30"
    >
      <div class="flex items-center justify-between">
        <span class="text-xs font-semibold text-n-slate-12">
          {{ t('CRM.TASKS.NEW_TASK_TITLE') }}
        </span>
        <Button
          variant="ghost"
          color="slate"
          size="xs"
          icon="i-lucide-x"
          @click="resetForm"
        />
      </div>

      <!-- Title Input -->
      <Input
        v-model="form.title"
        :placeholder="t('CRM.TASKS.TITLE_PLACEHOLDER')"
        :disabled="isCreating"
        autofocus
      />

      <!-- Type, Due Date & Assignee Grid -->
      <div class="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs">
        <div class="flex flex-col gap-1">
          <label class="font-medium text-n-slate-11">
            {{ t('CRM.TASKS.TYPE_LABEL') }} *
          </label>
          <Select
            v-model="form.task_type"
            :options="taskTypeOptions"
            :disabled="isCreating"
            class="w-full"
          />
        </div>

        <div class="flex flex-col gap-1">
          <label class="font-medium text-n-slate-11">
            {{ t('CRM.TASKS.DUE_DATE_LABEL') }} *
          </label>
          <Input
            v-model="form.due_date"
            type="datetime-local"
            :disabled="isCreating"
          />
        </div>
      </div>

      <!-- Assignee for Admin -->
      <div v-if="isAdmin" class="flex flex-col gap-1 text-xs">
        <label class="font-medium text-n-slate-11">
          {{ t('CRM.TASKS.ASSIGNEE_LABEL') }}
        </label>
        <Select
          v-model="form.user_id"
          :options="assigneeOptions"
          :disabled="isCreating"
          class="w-full"
        />
      </div>

      <!-- Action Buttons -->
      <div class="flex items-center justify-end gap-2 pt-2 border-t border-n-weak/60">
        <Button
          variant="faded"
          color="slate"
          size="xs"
          :label="t('CRM.TASKS.CANCEL')"
          @click="resetForm"
        />
        <Button
          variant="solid"
          color="blue"
          size="xs"
          :label="t('CRM.TASKS.SAVE')"
          :disable-confirm-button="isFormInvalid || isCreating"
          :is-loading="isCreating"
          @click="handleCreate"
        />
      </div>
    </div>

    <!-- Pending Tasks Section -->
    <div class="flex flex-col gap-2">
      <div class="flex items-center justify-between text-xs font-medium text-n-slate-11">
        <span>{{ t('CRM.TASKS.PENDING') }} ({{ pendingTasks.length }})</span>
      </div>

      <div
        v-if="pendingTasks.length === 0"
        class="py-4 text-center text-xs text-n-slate-10 border border-dashed border-n-weak rounded-lg"
      >
        {{ t('CRM.TASKS.NO_PENDING_TASKS') }}
      </div>

      <div
        v-for="task in pendingTasks"
        :key="task.id"
        class="flex items-start gap-2.5 p-2.5 rounded-lg border transition-colors bg-n-solid-1 hover:border-n-slate-6"
        :class="isOverdue(task.due_date) ? 'border-n-ruby-4 bg-n-ruby-2/20' : 'border-n-weak'"
      >
        <Checkbox
          :model-value="Boolean(task.completed_at)"
          :disabled="!canOperate"
          class="mt-0.5"
          @update:model-value="val => handleToggle(task, val)"
        />

        <div class="flex flex-col min-w-0 flex-1 gap-1">
          <div class="flex items-center justify-between gap-2">
            <span class="text-sm font-medium text-n-slate-12 truncate" :title="task.title">
              {{ task.title }}
            </span>
            <span
              v-if="isOverdue(task.due_date)"
              class="shrink-0 px-1.5 py-0.5 rounded text-[10px] font-semibold bg-n-ruby-2 text-n-ruby-11 outline outline-1 outline-n-ruby-4"
            >
              {{ t('CRM.TASKS.OVERDUE') }}
            </span>
          </div>

          <div class="flex items-center gap-3 text-xs text-n-slate-11 flex-wrap">
            <span class="inline-flex items-center gap-1">
              <span :class="[getTaskTypeIcon(task.task_type), 'size-3.5 text-n-slate-10']" />
              <span>{{ t(`CRM.TASKS.TYPE_${task.task_type.toUpperCase()}`) }}</span>
            </span>

            <span class="inline-flex items-center gap-1">
              <span class="i-lucide-clock size-3.5 text-n-slate-10" />
              <span>{{ formatDateTime(task.due_date) }}</span>
            </span>

            <span v-if="task.user" class="inline-flex items-center gap-1 ms-auto">
              <Avatar
                :name="task.user.name"
                :src="task.user.avatar_url || ''"
                :size="14"
              />
              <span class="truncate max-w-[100px]">{{ task.user.name }}</span>
            </span>
          </div>
        </div>
      </div>
    </div>

    <!-- Completed Tasks Section -->
    <div v-if="completedTasks.length > 0" class="flex flex-col gap-2 pt-2 border-t border-n-weak">
      <div class="flex items-center justify-between text-xs font-medium text-n-slate-10">
        <span>{{ t('CRM.TASKS.COMPLETED') }} ({{ completedTasks.length }})</span>
      </div>

      <div
        v-for="task in completedTasks"
        :key="task.id"
        class="flex items-start gap-2.5 p-2 rounded-lg border border-n-weak/50 bg-n-alpha-1/40 opacity-75"
      >
        <Checkbox
          :model-value="true"
          :disabled="!canOperate"
          class="mt-0.5"
          @update:model-value="val => handleToggle(task, val)"
        />

        <div class="flex flex-col min-w-0 flex-1">
          <span class="text-xs line-through text-n-slate-11 truncate" :title="task.title">
            {{ task.title }}
          </span>
          <span class="text-[10px] text-n-slate-10">
            {{ t('CRM.TASKS.COMPLETED_AT', { date: formatDateTime(task.completed_at) }) }}
          </span>
        </div>
      </div>
    </div>
  </div>
</template>
