<script setup>
const skeletonColumns = [1, 2, 3, 4];
const skeletonCards = [1, 2];
</script>

<template>
  <div class="flex-1 w-full overflow-x-hidden pb-4">
    <div class="flex items-start gap-4 h-full min-w-max px-1">
      <div
        v-for="col in skeletonColumns"
        :key="col"
        class="flex flex-col w-[300px] shrink-0 rounded-2xl border border-n-weak bg-n-alpha-1/60 dark:bg-n-solid-1/40 p-3 h-[600px] animate-pulse"
      >
        <!-- Skeleton Header -->
        <div class="flex flex-col gap-2 pb-3 border-b border-n-weak">
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-2">
              <div class="size-2.5 rounded-full bg-n-slate-3" />
              <div class="h-4 w-28 rounded bg-n-slate-3" />
            </div>
            <div class="h-4 w-6 rounded-full bg-n-slate-3" />
          </div>
          <div class="h-3 w-20 rounded bg-n-slate-3" />
        </div>

        <!-- Skeleton Cards -->
        <div class="flex flex-col gap-2.5 pt-3">
          <div
            v-for="card in skeletonCards"
            :key="card"
            class="flex flex-col gap-3 rounded-xl border border-n-weak bg-n-solid-1 dark:bg-n-solid-2 p-3.5"
          >
            <div class="flex justify-between items-start gap-2">
              <div class="h-4 w-3/4 rounded bg-n-slate-3" />
              <div class="h-3 w-10 rounded bg-n-slate-3" />
            </div>
            <div class="h-5 w-1/2 rounded bg-n-slate-3" />
            <div class="flex justify-between items-center pt-2 border-t border-n-weak/60">
              <div class="flex items-center gap-2">
                <div class="size-4.5 rounded-full bg-n-slate-3" />
                <div class="h-3 w-16 rounded bg-n-slate-3" />
              </div>
              <div class="size-4.5 rounded-full bg-n-slate-3" />
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
