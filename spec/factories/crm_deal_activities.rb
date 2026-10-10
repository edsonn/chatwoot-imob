FactoryBot.define do
  factory :crm_deal_activity, class: 'Crm::DealActivity' do
    account
    deal { association :crm_deal, account: account }
    activity_type { :stage_change }
    metadata { { 'from_position' => 0, 'to_position' => 1 } }
  end
end
