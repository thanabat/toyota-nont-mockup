class AddSyncChangeTrackingToSupplyForecasts < ActiveRecord::Migration[8.1]
  def up
    add_column :supply_forecasts, :first_seen_at, :datetime
    add_column :supply_forecasts, :last_sync_change_kind, :integer, default: 0, null: false

    execute <<~SQL.squish
      UPDATE supply_forecasts
      SET first_seen_at = COALESCE(first_seen_at, created_at, CURRENT_TIMESTAMP)
    SQL

    change_column_null :supply_forecasts, :first_seen_at, false
    add_index :supply_forecasts, :last_sync_change_kind
  end

  def down
    remove_index :supply_forecasts, :last_sync_change_kind
    remove_column :supply_forecasts, :last_sync_change_kind
    remove_column :supply_forecasts, :first_seen_at
  end
end
