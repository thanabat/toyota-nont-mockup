class AddStatusToStockPlanItems < ActiveRecord::Migration[8.1]
  def change
    add_column :stock_plan_items, :status, :integer, null: false, default: 0
    add_column :stock_plan_items, :incoming_at, :datetime
    add_index :stock_plan_items, :status
  end
end
