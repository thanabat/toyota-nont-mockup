require "test_helper"

class ForecastStockOrdersControllerTest < ActionDispatch::IntegrationTest
  setup do
    sync_run = ForecastSyncRun.create!(
      started_at: Time.current,
      trigger_mode: :manual,
      source_report_type: :weekly,
      status: :completed
    )

    @forecast_one = SupplyForecast.create!(
      forecast_sync_run: sync_run,
      source_key: "FC-WEEKLY-ORDER-L1",
      source_batch_key: "FC-WEEKLY-ORDER",
      source_line_no: 1,
      source_report_type: :weekly,
      model_code: "FORTUNER",
      model_label: "Fortuner Legender",
      color_name: "Platinum White Pearl",
      quantity_available: 3,
      estimated_production_date: Date.current + 10.days,
      last_synced_at: Time.current
    )

    @forecast_two = SupplyForecast.create!(
      forecast_sync_run: sync_run,
      source_key: "FC-WEEKLY-ORDER-L2",
      source_batch_key: "FC-WEEKLY-ORDER",
      source_line_no: 2,
      source_report_type: :weekly,
      model_code: "HILUX-REVO",
      model_label: "Hilux Revo Prerunner",
      color_name: "Super White",
      quantity_available: 2,
      estimated_production_date: Date.current + 12.days,
      last_synced_at: Time.current
    )

    @existing_stock_order = StockPlan.create!(
      plan_no: "SP-20260319-099",
      title: "สั่งเข้า Stock เดิม",
      requested_by: "allocation.team",
      status: :draft
    )
  end

  test "should redirect when no forecasts are selected" do
    get new_forecast_stock_orders_url(report_type: :weekly)

    assert_redirected_to forecasts_url(report_type: "weekly")
    follow_redirect!

    assert_select "div", /กรุณาเลือก forecast อย่างน้อย 1 รายการ/
  end

  test "should get bulk stock order selection page" do
    get new_forecast_stock_orders_url(forecast_ids: [@forecast_one.id, @forecast_two.id], report_type: :weekly)

    assert_response :success
    assert_select "h1", /สั่งเข้า Stock หลายรายการ/
    assert_select "td", /FC-WEEKLY-ORDER-L1/
    assert_select "td", /FC-WEEKLY-ORDER-L2/
    assert_select "option", /สั่งเข้า Stock เดิม/
  end

  test "should create stock order items in existing order" do
    assert_difference("StockPlanItem.count", 2) do
      post forecast_stock_orders_url, params: {
        stock_order_batch: {
          stock_order_id: @existing_stock_order.id,
          report_type: "weekly",
          forecast_ids: [@forecast_one.id, @forecast_two.id],
          items: {
            @forecast_one.id.to_s => { selected_quantity: 2, note: "สำหรับโชว์รูมปากเกร็ด" },
            @forecast_two.id.to_s => { selected_quantity: 1, note: "สำหรับสาขาบางบัวทอง" }
          }
        }
      }
    end

    assert_redirected_to stock_order_url(@existing_stock_order)
    follow_redirect!

    assert_select "td", /FC-WEEKLY-ORDER-L1/
    assert_select "td", /FC-WEEKLY-ORDER-L2/
  end

  test "should create new stock order when requested" do
    assert_difference("StockPlan.count", 1) do
      assert_difference("StockPlanItem.count", 2) do
        post forecast_stock_orders_url, params: {
          stock_order_batch: {
            stock_order_id: "new",
            new_stock_order_title: "สั่งเข้า Stock SUV รอบพิเศษ",
            report_type: "weekly",
            forecast_ids: [@forecast_one.id, @forecast_two.id],
            items: {
              @forecast_one.id.to_s => { selected_quantity: 1, note: "สำหรับลูกค้า fleet" },
              @forecast_two.id.to_s => { selected_quantity: 1, note: "สำหรับงานออกบูธ" }
            }
          }
        }
      end
    end

    created_order = StockPlan.order(:created_at).last
    assert_redirected_to stock_order_url(created_order)
  end

  test "should reject invalid quantity in one selected forecast" do
    assert_no_difference("StockPlanItem.count") do
      post forecast_stock_orders_url, params: {
        stock_order_batch: {
          stock_order_id: @existing_stock_order.id,
          report_type: "weekly",
          forecast_ids: [@forecast_one.id, @forecast_two.id],
          items: {
            @forecast_one.id.to_s => { selected_quantity: 5, note: "เกินจำนวน" },
            @forecast_two.id.to_s => { selected_quantity: 1, note: "ยังถูก" }
          }
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "div", /บันทึกไม่สำเร็จ/
    assert_select "li", /Fortuner Legender/
  end
end
