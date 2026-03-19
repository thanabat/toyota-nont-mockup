require "test_helper"

class IncomingStocksControllerTest < ActionDispatch::IntegrationTest
  setup do
    sync_run = ForecastSyncRun.create!(
      started_at: Time.current,
      trigger_mode: :manual,
      source_report_type: :monthly,
      status: :completed
    )

    incoming_forecast = SupplyForecast.create!(
      forecast_sync_run: sync_run,
      source_key: "FC-MONTHLY-INCOMING-L1",
      source_batch_key: "FC-MONTHLY-INCOMING",
      source_line_no: 1,
      source_report_type: :monthly,
      model_code: "CAMRY-HEV",
      model_label: "Camry HEV Premium Luxury",
      color_name: "Precious Metal",
      quantity_available: 2,
      estimated_production_date: Date.current + 20.days,
      estimated_arrival_date: Date.current + 35.days,
      last_synced_at: Time.current
    )

    ordered_forecast = SupplyForecast.create!(
      forecast_sync_run: sync_run,
      source_key: "FC-WEEKLY-ORDERED-L1",
      source_batch_key: "FC-WEEKLY-ORDERED",
      source_line_no: 1,
      source_report_type: :weekly,
      model_code: "HILUX-REVO",
      model_label: "Hilux Revo Prerunner",
      color_name: "Super White",
      quantity_available: 1,
      estimated_production_date: Date.current + 18.days,
      estimated_arrival_date: nil,
      last_synced_at: Time.current
    )

    plan = StockPlan.create!(plan_no: "SP-INCOMING-001", requested_by: "allocation.team")
    StockPlanItem.create!(stock_plan: plan, supply_forecast: incoming_forecast, selected_quantity: 1)
    StockPlanItem.create!(stock_plan: plan, supply_forecast: ordered_forecast, selected_quantity: 1)
  end

  test "should get incoming stock index with only incoming items" do
    get incoming_stocks_url

    assert_response :success
    assert_select "h1", /Stock กำลังเข้า/
    assert_select "td", /Camry HEV Premium Luxury/
    assert_select "th", /Stock/
    assert_select "th", /Location/
    assert_select "th", /In Stock/
    assert_select "td", /STK-/
    assert_select "th", text: /ETA/, count: 0
    assert_select "th", text: /Ref Key/, count: 0
    assert_select "td", text: /Hilux Revo Prerunner/, count: 0
  end
end
