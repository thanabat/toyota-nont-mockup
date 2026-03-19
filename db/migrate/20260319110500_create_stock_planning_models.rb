class CreateStockPlanningModels < ActiveRecord::Migration[8.1]
  def change
    create_table :forecast_sync_runs do |t|
      t.integer :trigger_mode, null: false, default: 0
      t.integer :source_report_type, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.string :initiated_by
      t.datetime :started_at, null: false
      t.datetime :completed_at
      t.integer :records_processed, null: false, default: 0
      t.integer :records_inserted, null: false, default: 0
      t.integer :records_updated, null: false, default: 0
      t.integer :records_archived, null: false, default: 0
      t.text :error_message

      t.timestamps
    end

    create_table :supply_forecasts do |t|
      t.references :forecast_sync_run, null: false, foreign_key: true
      t.string :source_key, null: false
      t.integer :source_report_type, null: false, default: 0
      t.string :model_code, null: false
      t.string :model_label
      t.string :grade
      t.string :color_code
      t.string :color_name
      t.integer :quantity_available, null: false, default: 0
      t.date :estimated_production_date
      t.date :estimated_arrival_date
      t.date :source_generated_on
      t.integer :status, null: false, default: 0
      t.datetime :last_synced_at, null: false
      t.datetime :selected_at
      t.datetime :change_detected_at

      t.timestamps
    end
    add_index :supply_forecasts, :source_key, unique: true
    add_index :supply_forecasts, :status
    add_index :supply_forecasts, :estimated_arrival_date
    add_check_constraint :supply_forecasts, "quantity_available >= 0", name: "supply_forecasts_quantity_available_non_negative"

    create_table :stock_plans do |t|
      t.string :plan_no, null: false
      t.integer :plan_type, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.string :requested_by, null: false
      t.string :title
      t.datetime :confirmed_at
      t.text :note

      t.timestamps
    end
    add_index :stock_plans, :plan_no, unique: true
    add_index :stock_plans, :status

    create_table :stock_plan_items do |t|
      t.references :stock_plan, null: false, foreign_key: true
      t.references :supply_forecast, null: false, foreign_key: true, index: { unique: true }
      t.integer :selected_quantity, null: false, default: 1
      t.text :note

      t.timestamps
    end
    add_check_constraint :stock_plan_items, "selected_quantity > 0", name: "stock_plan_items_selected_quantity_positive"
  end
end
