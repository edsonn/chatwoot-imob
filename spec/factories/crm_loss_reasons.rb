FactoryBot.define do
  factory :crm_loss_reason, class: 'Crm::LossReason' do
    account
    sequence(:name) { |n| "Motivo de Perda #{n}" }
    active { true }
  end
end
