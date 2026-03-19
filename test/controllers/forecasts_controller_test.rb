require "test_helper"

class ForecastsControllerTest < ActionDispatch::IntegrationTest
  setup do
    daily_sync_run = ForecastSyncRun.create!(
      started_at: Time.current,
      trigger_mode: :manual,
      source_report_type: :daily,
      status: :completed
    )
    weekly_sync_run = ForecastSyncRun.create!(
      started_at: 1.hour.ago,
      trigger_mode: :manual,
      source_report_type: :weekly,
      status: :completed
    )

    SupplyForecast.create!(
      forecast_sync_run: daily_sync_run,
      source_key: "FC-TEST-001-L1",
      source_batch_key: "FC-TEST-001",
      source_line_no: 1,
      source_report_type: :daily,
      model_code: "YARIS-ATIV",
      model_label: "Yaris Ativ Sport Premium",
      color_name: "Platinum White Pearl",
      quantity_available: 3,
      estimated_arrival_date: Date.current,
      last_synced_at: Time.current
    )

    SupplyForecast.create!(
      forecast_sync_run: weekly_sync_run,
      source_key: "FC-WEEKLY-001-L1",
      source_batch_key: "FC-WEEKLY-001",
      source_line_no: 1,
      source_report_type: :weekly,
      model_code: "HILUX-REVO",
      model_label: "Hilux Revo Prerunner",
      color_name: "Super White",
      quantity_available: 2,
      estimated_arrival_date: Date.current + 7.days,
      last_synced_at: Time.current
    )
  end

  test "should get index with daily as default tab" do
    get forecasts_url

    assert_response :success
    assert_select "h1", /Forecast Dashboard/
    assert_select "a", /Daily/
    assert_select "p", /FC-TEST-001/
    assert_select "td", /FC-TEST-001-L1/
    assert_select "td", /Yaris Ativ Sport Premium/
    assert_select "td", text: /FC-WEEKLY-001-L1/, count: 0
  end

  test "should filter to weekly tab" do
    get forecasts_url(report_type: "weekly")

    assert_response :success
    assert_select "p", /FC-WEEKLY-001/
    assert_select "td", /FC-WEEKLY-001-L1/
    assert_select "td", text: /FC-TEST-001-L1/, count: 0
  end

  test "should run manual sync for selected tab" do
    assert_difference "ForecastSyncRun.count", 1 do
      post sync_forecasts_url(report_type: "weekly")
    end

    assert_redirected_to forecasts_url(report_type: "weekly")
    follow_redirect!

    assert_response :success
    assert_select "div", /Weekly sync completed/
    assert_select "p", /New In Latest Sync/
  end
end
