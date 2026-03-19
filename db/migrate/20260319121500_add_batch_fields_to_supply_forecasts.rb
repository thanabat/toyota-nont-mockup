class AddBatchFieldsToSupplyForecasts < ActiveRecord::Migration[8.1]
  def up
    add_column :supply_forecasts, :source_batch_key, :string
    add_column :supply_forecasts, :source_line_no, :integer

    SupplyForecast.reset_column_information
    SupplyForecast.find_each do |forecast|
      forecast.update_columns(source_batch_key: forecast.source_key, source_line_no: 1)
    end

    change_column_null :supply_forecasts, :source_batch_key, false
    change_column_null :supply_forecasts, :source_line_no, false

    add_index :supply_forecasts, :source_batch_key
    add_index :supply_forecasts, %i[source_batch_key source_line_no], unique: true
  end

  def down
    remove_index :supply_forecasts, column: %i[source_batch_key source_line_no]
    remove_index :supply_forecasts, :source_batch_key
    remove_column :supply_forecasts, :source_line_no
    remove_column :supply_forecasts, :source_batch_key
  end
end
