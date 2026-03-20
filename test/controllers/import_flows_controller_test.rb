require "test_helper"

class ImportFlowsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sync_run = ForecastSyncRun.create!(
      started_at: Time.current,
      trigger_mode: :manual,
      source_report_type: :daily,
      status: :completed
    )

    SupplyForecast.create!(
      forecast_sync_run: sync_run,
      source_key: "FC-IMPORT-001-L1",
      source_batch_key: "FC-IMPORT-001",
      source_line_no: 1,
      source_report_type: :daily,
      model_code: "YARIS-ATIV",
      model_label: "Yaris Ativ Sport Premium",
      color_name: "Platinum White Pearl",
      quantity_available: 3,
      estimated_arrival_date: Date.current + 5.days,
      last_synced_at: Time.current
    )
  end

  test "should redirect to forecasts while auto sync flow is active" do
    get import_flow_url

    assert_redirected_to forecasts_url
  end

  test "should get import flow page when import flow is active" do
    patch prototype_flow_url, params: { flow: :import_file, return_to: "/import_flow" }
    get import_flow_url

    assert_response :success
    assert_select "h1", /นำเข้าไฟล์อัปเดตจากระบบบริษัทแม่/
    assert_select "button", /นำเข้าไฟล์ Daily/
    assert_select "h3", /FC-IMPORT-001/
  end

  test "should run file import for current report type" do
    patch prototype_flow_url, params: { flow: :import_file, return_to: "/import_flow" }

    assert_difference "ForecastSyncRun.count", 1 do
      post import_flow_import_url(report_type: :daily)
    end

    assert_redirected_to import_flow_url(report_type: :daily)
  end
end
