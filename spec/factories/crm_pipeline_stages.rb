FactoryBot.define do
  factory :crm_pipeline_stage, class: 'Crm::PipelineStage' do
    account
    pipeline { association :crm_pipeline, account: account }
    sequence(:name) { |n| "Etapa #{n}" }
    position { 0 }
    stage_type { :open }
    color { '#3B82F6' }

    trait :won do
      stage_type { :won }
      color { '#10B981' }
    end

    trait :lost do
      stage_type { :lost }
      color { '#EF4444' }
    end
  end
end
