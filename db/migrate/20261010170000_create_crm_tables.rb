class CreateCrmTables < ActiveRecord::Migration[7.1]
  def change
    create_crm_pipelines
    create_crm_pipeline_stages
    create_crm_loss_reasons
    create_crm_deals
    create_crm_deal_activities
    create_crm_deal_tasks
  end

  private

  def create_crm_pipelines
    create_table :crm_pipelines do |t|
      t.references :account, null: false, index: true
      t.string :name, null: false
      t.integer :position, default: 0, null: false
      t.boolean :is_default, default: false, null: false

      t.timestamps
    end

    add_index :crm_pipelines, [:account_id, :position]
  end

  def create_crm_pipeline_stages
    create_table :crm_pipeline_stages do |t|
      t.references :account, null: false, index: true
      t.references :crm_pipeline, null: false, index: true
      t.string :name, null: false
      t.integer :position, default: 0, null: false
      t.integer :stage_type, default: 0, null: false
      t.string :color, default: '#3B82F6', null: false

      t.timestamps
    end

    add_index :crm_pipeline_stages, [:crm_pipeline_id, :position]
  end

  def create_crm_loss_reasons
    create_table :crm_loss_reasons do |t|
      t.references :account, null: false, index: true
      t.string :name, null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :crm_loss_reasons, [:account_id, :active]
  end

  def create_crm_deals
    create_table :crm_deals do |t|
      t.references :account, null: false, index: true
      t.references :crm_pipeline_stage, null: false, index: true
      t.references :contact, null: false, index: true
      t.references :conversation, index: true
      t.references :assignee, references: :users, index: true
      t.string :title, null: false
      t.decimal :value, precision: 14, scale: 2, default: 0.0, null: false
      t.decimal :final_value, precision: 14, scale: 2
      t.string :currency, default: 'BRL', null: false
      t.integer :status, default: 0, null: false
      t.integer :priority, default: 1, null: false
      t.string :source
      t.string :business_type
      t.text :next_action
      t.datetime :next_action_at
      t.datetime :closed_at
      t.references :crm_loss_reason, index: true
      t.text :loss_notes
      t.jsonb :custom_attributes, default: {}, null: false
      t.integer :position, default: 0, null: false
      t.datetime :last_activity_at

      t.timestamps
    end

    add_index :crm_deals, [:account_id, :status]
    add_index :crm_deals, [:crm_pipeline_stage_id, :position]
    add_index :crm_deals, [:account_id, :last_activity_at]
  end

  def create_crm_deal_activities
    create_table :crm_deal_activities do |t|
      t.references :account, null: false, index: true
      t.references :crm_deal, null: false, index: true
      t.references :user, index: true
      t.integer :activity_type, null: false
      t.references :from_stage, references: :crm_pipeline_stages, index: true
      t.references :to_stage, references: :crm_pipeline_stages, index: true
      t.text :notes
      t.jsonb :metadata, default: {}, null: false

      t.timestamps
    end

    add_index :crm_deal_activities, [:crm_deal_id, :created_at]
  end

  def create_crm_deal_tasks
    create_table :crm_deal_tasks do |t|
      t.references :account, null: false, index: true
      t.references :crm_deal, null: false, index: true
      t.references :user, null: false, index: true
      t.string :title, null: false
      t.integer :task_type, default: 3, null: false
      t.datetime :due_date, null: false
      t.datetime :completed_at

      t.timestamps
    end

    add_index :crm_deal_tasks, [:account_id, :due_date]
    add_index :crm_deal_tasks, [:user_id, :due_date]
  end
end
