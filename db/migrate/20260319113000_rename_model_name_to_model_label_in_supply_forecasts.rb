class RenameModelNameToModelLabelInSupplyForecasts < ActiveRecord::Migration[8.1]
  def change
    return unless column_exists?(:supply_forecasts, :model_name)

    rename_column :supply_forecasts, :model_name, :model_label
  end
end
