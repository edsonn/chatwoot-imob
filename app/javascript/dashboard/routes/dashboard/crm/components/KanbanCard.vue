<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import { formatCurrencyAmount } from 'dashboard/constants/billing';

const props = defineProps({
  deal: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['edit', 'move', 'won', 'lost']);

const { t } = useI18n();
const store = useStore();

const showMenu = ref(false);

const currentUserId = computed(() => store.getters.getCurrentUserID);
const isAdmin = computed(() => store.getters.getCurrentRole === 'administrator');

const canOperate = computed(() => {
  if (isAdmin.value) return true;
  const assigneeId = props.deal.assignee?.id;
  return !assigneeId || assigneeId === currentUserId.value;
});

const menuItems = computed(() => [
  {
    label: t('CRM.ACTIONS.EDIT'),
    action: 'edit',
    icon: 'i-lucide-pencil',
  },
  {
    label: t('CRM.ACTIONS.MOVE'),
    action: 'move',
    icon: 'i-lucide-arrow-right',
  },
  {
    label: t('CRM.ACTIONS.MARK_WON'),
    action: 'won',
    icon: 'i-lucide-trophy',
  },
  {
    label: t('CRM.ACTIONS.MARK_LOST'),
    action: 'lost',
    icon: 'i-lucide-x-circle',
  },
]);

const handleMenuAction = ({ action }) => {
  showMenu.value = false;
  emit(action, props.deal);
};

const formattedValue = computed(() => {
  const val = Number(props.deal.value || 0);
  const currency = props.deal.currency || 'BRL';
  try {
    return formatCurrencyAmount(val, currency);
  } catch {
    return new Intl.NumberFormat('pt-BR', {
      style: 'currency',
      currency: currency.toUpperCase(),
    }).format(val);
  }
});

const priorityConfig = computed(() => {
  const map = {
    urgent: {
      label: 'Urgente',
      classes: 'bg-n-ruby-2 text-n-ruby-11 outline-n-ruby-4',
    },
    high: {
      label: 'Alta',
      classes: 'bg-n-amber-2 text-n-amber-11 outline-n-amber-4',
    },
    medium: {
      label: 'Média',
      classes: 'bg-n-blue-2 text-n-blue-11 outline-n-blue-4',
    },
    low: {
      label: 'Baixa',
      classes: 'bg-n-slate-3 text-n-slate-11 outline-n-slate-5',
    },
  };
  return map[props.deal.priority] || map.medium;
});
</script>

<template>
  <div
    class="group relative flex flex-col gap-2.5 rounded-xl border border-n-weak bg-n-solid-1 p-3.5 shadow-sm transition-all duration-150 hover:border-n-slate-6 hover:shadow dark:bg-n-solid-2 cursor-default select-none"
  >
    <!-- Card Header: Title, Priority & Actions Menu -->
    <div class="flex items-start justify-between gap-2">
      <div class="flex flex-col gap-1 min-w-0 flex-1">
        <h4
          class="text-sm font-medium text-n-slate-12 line-clamp-2 leading-snug"
          :title="deal.title"
        >
          {{ deal.title }}
        </h4>
        <div class="flex items-center gap-1.5 flex-wrap">
          <span
            v-if="deal.priority"
            class="shrink-0 inline-flex items-center rounded px-1.5 py-0.5 text-[10px] font-medium outline outline-1 -outline-offset-1"
            :class="priorityConfig.classes"
          >
            {{ priorityConfig.label }}
          </span>
        </div>
      </div>

      <!-- Actions Dropdown (Only when canOperate is true) -->
      <div
        v-if="canOperate"
        v-on-clickaway="() => (showMenu = false)"
        class="relative shrink-0"
      >
        <Button
          variant="ghost"
          color="slate"
          size="xs"
          icon="i-lucide-more-vertical"
          class="opacity-0 group-hover:opacity-100 transition-opacity"
          :class="{ '!opacity-100': showMenu }"
          :aria-label="t('CRM.ACTIONS.MENU_LABEL')"
          @click="showMenu = !showMenu"
        />

        <DropdownMenu
          v-if="showMenu"
          :menu-items="menuItems"
          class="top-7 right-0 min-w-36 z-50 shadow-md"
          @action="handleMenuAction"
        />
      </div>
    </div>

    <!-- Value -->
    <div class="text-base font-semibold text-n-slate-12 tracking-tight">
      {{ formattedValue }}
    </div>

    <!-- Contact & Assignee Footer -->
    <div
      class="flex items-center justify-between pt-2 border-t border-n-weak/60 text-xs text-n-slate-11"
    >
      <!-- Contact -->
      <div
        class="flex items-center gap-1.5 min-w-0 max-w-[60%]"
        :title="deal.contact?.name || t('CRM.NO_CONTACT')"
      >
        <Avatar
          v-if="deal.contact"
          :name="deal.contact.name || 'Lead'"
          :src="deal.contact.thumbnail || ''"
          :size="18"
          class="shrink-0"
        />
        <span class="truncate">
          {{ deal.contact?.name || t('CRM.NO_CONTACT') }}
        </span>
      </div>

      <!-- Assignee -->
      <div
        class="flex items-center gap-1.5 shrink-0"
        :title="deal.assignee?.name || t('CRM.UNASSIGNED')"
      >
        <Avatar
          v-if="deal.assignee"
          :name="deal.assignee.name || 'Agente'"
          :src="deal.assignee.avatar_url || ''"
          :size="18"
          class="shrink-0"
        />
        <span v-else class="text-[11px] text-n-slate-10 italic">
          {{ t('CRM.UNASSIGNED') }}
        </span>
      </div>
    </div>
  </div>
</template>
