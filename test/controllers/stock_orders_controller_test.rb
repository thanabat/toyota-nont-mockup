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
    assert_select "h1", /Stock/
    assert_select "a", /ทั้งหมด/
    assert_select "a", /สั่งเข้าแล้ว/
    assert_select "a", /กำลังเข้า/
    assert_select "td", /Hilux Revo Prerunner/
    assert_select "span", /สั่งเข้าแล้ว/
    assert_select "th", text: /ฝ่ายขาย/, count: 0
  end

  test "should filter stock workspace to incoming items" do
    item = @stock_order.stock_plan_items.last
    item.supply_forecast.update!(estimated_arrival_date: Date.current + 21.days)
    item.update!(status: :incoming, incoming_at: Time.current)

    get stock_orders_url(tab: :incoming)

    assert_response :success
    assert_select "td", /Hilux Revo Prerunner/
    assert_select "span", /กำลังเข้า/
    assert_select "th", text: /ฝ่ายขาย/, count: 0
  end

  test "should check latest status and move ordered item to incoming when data completes" do
    assert_difference "ForecastSyncRun.count", 1 do
      post check_latest_stock_orders_url(tab: :ordered)
    end

    assert_redirected_to stock_orders_url(tab: :ordered)

    @stock_order.stock_plan_items.last.reload
    assert_predicate @stock_order.stock_plan_items.last, :status_incoming?
  end

  test "should default to incoming tab in sales mode" do
    item = @stock_order.stock_plan_items.last
    item.supply_forecast.update!(estimated_arrival_date: Date.current + 21.days)
    item.update!(status: :incoming, incoming_at: Time.current)

    patch workspace_mode_url, params: { mode: :sales, return_to: "/stock_orders" }
    get stock_orders_url

    assert_response :success
    assert_select "p", /Sales Workspace/
    assert_select "h1", /รถที่กำลังเข้า/
    assert_select "h2", /รายการรถที่ฝ่ายขายดูได้ตอนนี้/
    assert_select "td", /Hilux Revo Prerunner/
    assert_select "th", /เซลล์ที่ติดตาม/
    assert_select "a", text: /ทั้งหมด/, count: 0
    assert_select "th", text: /รายการสั่งเข้า Stock/, count: 0
    assert_select "button", /ติดตาม/
  end

  test "should get stock order detail" do
    get stock_order_url(@stock_order)

    assert_response :success
    assert_select "h1", /สั่งเข้า Stock Hilux รอบด่วน/
    assert_select "td", /FC-WEEKLY-TEST-L1/
    assert_select "span", /สั่งแล้ว/
  end
end
