require "test_helper"

class ImportFlowsControllerTest < ActionDispatch::IntegrationTest
  setup do
    monthly_sync_run = ForecastSyncRun.create!(
      started_at: Time.current,
      trigger_mode: :manual,
      source_report_type: :monthly,
      status: :completed
    )

    SupplyForecast.create!(
      forecast_sync_run: monthly_sync_run,
      source_key: "FC-IMPORT-001-L1",
      source_batch_key: "FC-IMPORT-001",
      source_line_no: 1,
      source_report_type: :monthly,
      model_code: "YARIS-ATIV",
      model_label: "Yaris Ativ Sport Premium",
      color_name: "Platinum White Pearl",
      quantity_available: 3,
      estimated_arrival_date: Date.current + 5.days,
      last_synced_at: Time.current
    )

    weekly_sync_run = ForecastSyncRun.create!(
      started_at: 1.hour.ago,
      trigger_mode: :manual,
      source_report_type: :weekly,
      status: :completed
    )

    SupplyForecast.create!(
      forecast_sync_run: weekly_sync_run,
      source_key: "FC-IMPORT-002-L1",
      source_batch_key: "FC-IMPORT-002",
      source_line_no: 1,
      source_report_type: :weekly,
      model_code: "CAMRY-HEV",
      model_label: "Camry HEV Premium Luxury",
      color_name: "Precious Metal",
      quantity_available: 2,
      estimated_arrival_date: Date.current + 12.days,
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
    assert_select "input[type=file][name=import_file]"
    assert_select "button", /Browse file/
    assert_select "button", /นำเข้าไฟล์/
    assert_select "p", /ยังไม่มีข้อมูลนำเข้าใน session นี้/
    assert_select "div", /กดนำเข้าไฟล์ครั้งแรกเพื่อเริ่มสร้างข้อมูลใน flow นี้/
    assert_select "p", /ยังไม่มีข้อมูลนำเข้า/
    assert_select "p", /สร้างใหม่/
    assert_select "p", /อัปเดตข้อมูล/
    assert_select "p", /ไม่มีการเปลี่ยนแปลง/
  end

  test "should run file import for current report type" do
    patch prototype_flow_url, params: { flow: :import_file, return_to: "/import_flow" }

    assert_difference "ForecastSyncRun.count", 1 do
      post import_flow_import_url
    end

    assert_redirected_to import_flow_url(report_type: :monthly)
  end

  test "should show imported data after first import" do
    patch prototype_flow_url, params: { flow: :import_file, return_to: "/import_flow" }
    post import_flow_import_url
    follow_redirect!

    assert_response :success
    assert_select "p", /ตรวจพบเป็น Monthly feed/
    assert_select "h3", /FC-MONTHLY/
    assert_select "th", /รอบ/
    assert_select "span", /สร้างรายการใหม่/
    assert_select "span", text: /อัปเดตข้อมูล/, count: 0
    assert_select "span", /Monthly/
    assert_select "p", /สร้างใหม่/
    assert_select "p", /อัปเดตข้อมูล/
    assert_select "p", /ไม่มีการเปลี่ยนแปลง/
  end

  test "should compare weekly import against the previous monthly file" do
    patch prototype_flow_url, params: { flow: :import_file, return_to: "/import_flow" }
    post import_flow_import_url
    post import_flow_import_url
    follow_redirect!

    assert_response :success
    assert_select "p", /ตรวจพบเป็น Weekly feed/
    assert_select "span", /อัปเดตข้อมูล/
    assert_select "span", /Weekly/
    assert_select "td", /Camry HEV Premium Luxury/
  end
end
