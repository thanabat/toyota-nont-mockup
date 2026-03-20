require "test_helper"

class SalesInterestsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sync_run = ForecastSyncRun.create!(
      started_at: Time.current,
      trigger_mode: :manual,
      source_report_type: :monthly,
      status: :completed
    )

    forecast = SupplyForecast.create!(
      forecast_sync_run: sync_run,
      source_key: "FC-MONTHLY-SALES-L1",
      source_batch_key: "FC-MONTHLY-SALES",
      source_line_no: 1,
      source_report_type: :monthly,
      model_code: "CAMRY-HEV",
      model_label: "Camry HEV Premium Luxury",
      color_name: "Precious Metal",
      quantity_available: 2,
      estimated_production_date: Date.current + 14.days,
      estimated_arrival_date: Date.current + 28.days,
      last_synced_at: Time.current
    )

    stock_plan = StockPlan.create!(
      plan_no: "SP-SALES-001",
      title: "รอบที่ฝ่ายขายกำลังติดตาม",
      requested_by: "allocation.team"
    )

    @stock_plan_item = StockPlanItem.create!(
      stock_plan: stock_plan,
      supply_forecast: forecast,
      selected_quantity: 1,
      status: :incoming,
      incoming_at: Time.current
    )
  end

  test "should get new sales interest form for incoming stock" do
    get new_sales_interest_url(stock_plan_item_id: @stock_plan_item.id, tab: :incoming)

    assert_response :success
    assert_select "h1", /ติดตาม Stock กำลังเข้า/
    assert_select "form"
    assert_select "input[name='sales_interest\\[sales_name\\]']"
  end

  test "should create sales interest" do
    assert_difference "SalesInterest.count", 1 do
      post sales_interests_url, params: {
        return_tab: "incoming",
        sales_interest: {
          stock_plan_item_id: @stock_plan_item.id,
          sales_name: "กฤตภาส",
          branch_name: "โชว์รูมบางบัวทอง",
          status: "prospective_customer",
          note: "มีลูกค้ามุ่งหวังสีนี้อยู่"
        }
      }
    end

    assert_redirected_to stock_orders_url(tab: :incoming)
    assert_equal "prospective_customer", SalesInterest.last.status
  end
end
