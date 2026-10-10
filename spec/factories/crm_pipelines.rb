FactoryBot.define do
  factory :crm_pipeline, class: 'Crm::Pipeline' do
    account
    sequence(:name) { |n| "Funil #{n}" }
    position { 0 }
    is_default { false }
  end
end
