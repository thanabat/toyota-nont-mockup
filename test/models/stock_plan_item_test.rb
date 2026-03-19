require "test_helper"

class StockPlanItemTest < ActiveSupport::TestCase
  setup do
    @sync_run = ForecastSyncRun.create!(
      started_at: Time.current,
      trigger_mode: :manual,
      source_report_type: :weekly,
      status: :completed
    )
    @forecast = SupplyForecast.create!(
      forecast_sync_run: @sync_run,
      source_key: "FORECAST-003",
      source_report_type: :weekly,
      model_code: "COROLLA-CROSS",
      quantity_available: 2,
      last_synced_at: Time.current
    )
    @plan = StockPlan.create!(plan_no: "SP-TEST-002", requested_by: "allocation.team")
  end

  test "selected quantity must fit forecast quantity" do
    item = StockPlanItem.new(stock_plan: @plan, supply_forecast: @forecast, selected_quantity: 3)

    assert_not item.valid?
    assert_includes item.errors[:selected_quantity], "must be less than or equal to the forecast quantity"
  end

  test "a forecast can only be selected once" do
    StockPlanItem.create!(stock_plan: @plan, supply_forecast: @forecast, selected_quantity: 1)

    second_plan = StockPlan.create!(plan_no: "SP-TEST-003", requested_by: "allocation.team")
    duplicate = StockPlanItem.new(stock_plan: second_plan, supply_forecast: @forecast, selected_quantity: 1)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:supply_forecast_id], "has already been taken"
  end
end
