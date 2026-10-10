FactoryBot.define do
  factory :crm_deal_task, class: 'Crm::DealTask' do
    account
    deal { association :crm_deal, account: account }
    sequence(:title) { |n| "Visita imóvel #{n}" }
    task_type { :visit }
    due_date { 1.day.from_now }

    before(:build) do |task|
      if task.user.blank?
        user = create(:user)
        create(:account_user, account: task.account, user: user)
        task.user = user
      end
    end

    trait :completed do
      completed_at { Time.current }
    end
  end
end
