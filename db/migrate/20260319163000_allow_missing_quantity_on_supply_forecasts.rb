class AllowMissingQuantityOnSupplyForecasts < ActiveRecord::Migration[8.1]
  def change
    change_column_default :supply_forecasts, :quantity_available, from: 0, to: nil
    change_column_null :supply_forecasts, :quantity_available, true
  end
end
