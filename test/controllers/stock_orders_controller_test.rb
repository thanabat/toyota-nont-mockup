require "test_helper"

class StockOrdersControllerTest < ActionDispatch::IntegrationTest
  setup do
    sync_run = ForecastSyncRun.create!(
      started_at: Time.current,
      trigger_mode: :manual,
      source_report_type: :weekly,
      status: :completed
    )

    forecast = SupplyForecast.create!(
      forecast_sync_run: sync_run,
      source_key: "FC-WEEKLY-TEST-L1",
      source_batch_key: "FC-WEEKLY-TEST",
      source_line_no: 1,
      source_report_type: :weekly,
      model_code: "HILUX-REVO",
      model_label: "Hilux Revo Prerunner",
      color_name: "Super White",
      quantity_available: 2,
      estimated_production_date: Date.current + 7.days,
      last_synced_at: Time.current
    )

    @stock_order = StockPlan.create!(
      plan_no: "SP-TEST-ORDER-001",
      title: "สั่งเข้า Stock Hilux รอบด่วน",
      requested_by: "allocation.team",
      status: :draft
    )

    StockPlanItem.create!(
      stock_plan: @stock_order,
      supply_forecast: forecast,
      selected_quantity: 1
    )
  end

  test "should get stock order index" do
    get stock_orders_url

    assert_response :success
    assert_select "h1", /รายการสั่งเข้า Stock/
    assert_select "h3", /สั่งเข้า Stock Hilux รอบด่วน/
  end

  test "should get stock order detail" do
    get stock_order_url(@stock_order)

    assert_response :success
    assert_select "h1", /สั่งเข้า Stock Hilux รอบด่วน/
    assert_select "td", /FC-WEEKLY-TEST-L1/
    assert_select "span", /สั่งแล้ว/
  end
end
