<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  activities: {
    type: Array,
    default: () => [],
  },
});

const { t } = useI18n();

const sortedActivities = computed(() => {
  return (props.activities || [])
    .slice()
    .sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
});

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

const getActivityConfig = activity => {
  switch (activity.activity_type) {
    case 'stage_change':
      return {
        icon: 'i-lucide-arrow-right',
        iconBg: 'bg-n-blue-2 text-n-blue-11',
        title: activity.from_stage && activity.to_stage
          ? t('CRM.TIMELINE.STAGE_CHANGED_FROM_TO', {
              from: activity.from_stage.name,
              to: activity.to_stage.name,
            })
          : activity.to_stage
            ? t('CRM.TIMELINE.STAGE_CHANGED_TO', { to: activity.to_stage.name })
            : t('CRM.TIMELINE.STAGE_CHANGED'),
      };
    case 'task_created':
      return {
        icon: 'i-lucide-plus-circle',
        iconBg: 'bg-n-violet-2 text-n-violet-11',
        title: activity.metadata?.task_title
          ? t('CRM.TIMELINE.TASK_CREATED_WITH_TITLE', {
              title: activity.metadata.task_title,
            })
          : t('CRM.TIMELINE.TASK_CREATED'),
      };
    case 'task_completed':
      return {
        icon: 'i-lucide-check-circle-2',
        iconBg: 'bg-n-teal-2 text-n-teal-11',
        title: activity.metadata?.task_title
          ? t('CRM.TIMELINE.TASK_COMPLETED_WITH_TITLE', {
              title: activity.metadata.task_title,
            })
          : t('CRM.TIMELINE.TASK_COMPLETED'),
      };
    case 'status_change':
      return {
        icon: 'i-lucide-flag',
        iconBg: 'bg-n-amber-2 text-n-amber-11',
        title: t('CRM.TIMELINE.STATUS_CHANGED'),
      };
    case 'assignment_change':
      return {
        icon: 'i-lucide-user-check',
        iconBg: 'bg-n-blue-2 text-n-blue-11',
        title: t('CRM.TIMELINE.ASSIGNMENT_CHANGED'),
      };
    case 'value_change':
      return {
        icon: 'i-lucide-dollar-sign',
        iconBg: 'bg-n-teal-2 text-n-teal-11',
        title: t('CRM.TIMELINE.VALUE_CHANGED'),
      };
    case 'note':
      return {
        icon: 'i-lucide-message-square',
        iconBg: 'bg-n-slate-3 text-n-slate-11',
        title: activity.notes || t('CRM.TIMELINE.NOTE_ADDED'),
      };
    default:
      return {
        icon: 'i-lucide-clock',
        iconBg: 'bg-n-slate-3 text-n-slate-11',
        title: activity.notes || t('CRM.TIMELINE.ACTIVITY_RECORDED'),
      };
  }
};
</script>

<template>
  <div class="flex flex-col gap-4 py-2">
    <div
      v-if="sortedActivities.length === 0"
      class="flex flex-col items-center justify-center py-8 text-center text-xs text-n-slate-10"
    >
      <span class="i-lucide-history size-5 mb-1.5 opacity-60" />
      {{ t('CRM.TIMELINE.NO_ACTIVITIES') }}
    </div>

    <div v-else class="relative flex flex-col gap-5 ps-6 before:absolute before:top-2 before:bottom-2 before:start-2.5 before:w-px before:bg-n-weak">
      <div
        v-for="activity in sortedActivities"
        :key="activity.id"
        class="relative flex flex-col gap-1 text-sm"
      >
        <!-- Activity Icon Dot -->
        <span
          class="absolute -start-6 top-0.5 size-5 rounded-full flex items-center justify-center shrink-0 shadow-xs"
          :class="getActivityConfig(activity).iconBg"
        >
          <span :class="[getActivityConfig(activity).icon, 'size-3']" />
        </span>

        <!-- Activity Header & Title -->
        <div class="flex items-center justify-between gap-2">
          <span class="font-medium text-n-slate-12 text-xs leading-snug">
            {{ getActivityConfig(activity).title }}
          </span>
          <span class="text-[11px] text-n-slate-10 shrink-0">
            {{ formatDateTime(activity.created_at) }}
          </span>
        </div>

        <!-- Activity User / Notes -->
        <div class="flex items-center gap-2 text-xs text-n-slate-11">
          <span v-if="activity.user?.name" class="font-normal truncate">
            {{ t('CRM.TIMELINE.BY_USER', { user: activity.user.name }) }}
          </span>
        </div>

        <p
          v-if="activity.notes && activity.activity_type !== 'note'"
          class="mt-1 p-2 rounded-lg bg-n-alpha-1 border border-n-weak text-xs text-n-slate-11 leading-relaxed"
        >
          {{ activity.notes }}
        </p>
      </div>
    </div>
  </div>
</template>
