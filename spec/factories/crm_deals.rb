FactoryBot.define do
  factory :crm_deal, class: 'Crm::Deal' do
    account
    stage { association :crm_pipeline_stage, account: account }
    contact { association :contact, account: account }
    sequence(:title) { |n| "Oportunidade Imobiliária #{n}" }
    value { 500_000.00 }
    currency { 'BRL' }
    status { :open }
    priority { :medium }
    position { 0 }
    business_type { 'sale' }
    custom_attributes { {} }

    trait :with_assignee do
      after(:build) do |deal|
        user = create(:user)
        create(:account_user, account: deal.account, user: user)
        deal.assignee = user
      end
    end

    trait :won do
      stage { association :crm_pipeline_stage, :won, account: account }
      status { :won }
      closed_at { Time.current }
      final_value { 480_000.00 }
    end

    trait :lost do
      stage { association :crm_pipeline_stage, :lost, account: account }
      status { :lost }
      closed_at { Time.current }
      loss_reason { association :crm_loss_reason, account: account }
      loss_notes { 'Preço fora do orçamento do cliente' }
    end
  end
end
