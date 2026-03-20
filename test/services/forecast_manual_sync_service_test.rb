require "test_helper"

class ForecastManualSyncServiceTest < ActiveSupport::TestCase
  setup do
    @sync_run = ForecastSyncRun.create!(
      started_at: Time.current,
      trigger_mode: :manual,
      source_report_type: :daily,
      status: :completed
    )

    @kept_forecast = SupplyForecast.create!(
      forecast_sync_run: @sync_run,
      source_key: "FC-DAILY-LEGACY-L1",
      source_batch_key: "FC-DAILY-LEGACY",
      source_line_no: 1,
      source_report_type: :daily,
      model_code: "YARIS-ATIV",
      model_label: "Yaris Ativ Sport Premium",
      color_name: "Platinum White Pearl",
      quantity_available: 3,
      estimated_arrival_date: Date.current + 7.days,
      last_synced_at: Time.current
    )

    @archived_forecast = SupplyForecast.create!(
      forecast_sync_run: @sync_run,
      source_key: "FC-DAILY-LEGACY-L4",
      source_batch_key: "FC-DAILY-LEGACY",
      source_line_no: 4,
      source_report_type: :daily,
      model_code: "RAIZE",
      model_label: "Raize Turbo",
      color_name: "Turquoise",
      quantity_available: 2,
      estimated_arrival_date: Date.current + 8.days,
      last_synced_at: Time.current
    )

    SupplyForecast.create!(
      forecast_sync_run: @sync_run,
      source_key: "FC-DAILY-LEGACY-L2",
      source_batch_key: "FC-DAILY-LEGACY",
      source_line_no: 2,
      source_report_type: :daily,
      model_code: "YARIS-CROSS",
      model_label: "Yaris Cross HEV",
      color_name: "Urban Metal",
      quantity_available: 4,
      estimated_arrival_date: Date.current + 9.days,
      last_synced_at: Time.current
    )

    SupplyForecast.create!(
      forecast_sync_run: @sync_run,
      source_key: "FC-DAILY-LEGACY-L3",
      source_batch_key: "FC-DAILY-LEGACY",
      source_line_no: 3,
      source_report_type: :daily,
      model_code: "COROLLA-ALTIS",
      model_label: "Corolla Altis GR Sport",
      color_name: "Attitude Black Mica",
      quantity_available: 1,
      estimated_arrival_date: Date.current + 10.days,
      last_synced_at: Time.current
    )
  end

  test "manual sync inserts new rows and archives rows missing from snapshot" do
    service = ForecastManualSyncService.new(report_type: :daily)

    result = service.call

    assert_predicate result.sync_run, :status_completed?
    assert_operator result.inserted, :>, 0
    assert_operator result.updated, :>, 0
    assert_operator result.archived, :>, 0

    inserted_rows = SupplyForecast.where(forecast_sync_run: result.sync_run).last_sync_change_kind_inserted
    assert_predicate inserted_rows, :exists?

    @archived_forecast.reload
    assert_predicate @archived_forecast, :status_cancelled?
    assert_predicate @archived_forecast, :last_sync_change_kind_archived?

    @kept_forecast.reload
    assert_equal result.sync_run, @kept_forecast.forecast_sync_run
    assert_equal "FC-DAILY-#{Date.current.strftime('%Y%m%d')}-002", @kept_forecast.source_batch_key
  end

  test "manual sync promotes ordered weekly item to incoming when eta arrives" do
    weekly_sync_run = ForecastSyncRun.create!(
      started_at: 2.hours.ago,
      trigger_mode: :manual,
      source_report_type: :weekly,
      status: :completed
    )

    weekly_forecast = SupplyForecast.create!(
      forecast_sync_run: weekly_sync_run,
      source_key: "FC-WEEKLY-LEGACY-L1",
      source_batch_key: "FC-WEEKLY-LEGACY",
      source_line_no: 1,
      source_report_type: :weekly,
      model_code: "FORTUNER",
      model_label: "Fortuner Legender",
      color_name: "Platinum White Pearl",
      quantity_available: 2,
      estimated_production_date: Date.current + 14.days,
      estimated_arrival_date: nil,
      last_synced_at: Time.current
    )

    plan = StockPlan.create!(plan_no: "SP-SYNC-001", requested_by: "allocation.team")
    item = StockPlanItem.create!(stock_plan: plan, supply_forecast: weekly_forecast, selected_quantity: 1)

    result = ForecastManualSyncService.new(report_type: :weekly).call

    item.reload
    weekly_forecast.reload

    assert_predicate item, :status_incoming?
    assert_not_nil weekly_forecast.estimated_arrival_date
    assert_operator result.promoted_to_incoming, :>=, 1
  end

  test "monthly import keeps data at a rough planning level" do
    monthly_sync_run = ForecastSyncRun.create!(
      started_at: 2.hours.ago,
      trigger_mode: :manual,
      source_report_type: :monthly,
      status: :completed
    )

    SupplyForecast.create!(
      forecast_sync_run: monthly_sync_run,
      source_key: "FC-MONTHLY-LEGACY-L1",
      source_batch_key: "FC-MONTHLY-LEGACY",
      source_line_no: 1,
      source_report_type: :monthly,
      model_code: "CAMRY",
      model_label: "Camry HEV Premium Luxury",
      color_name: "Precious Metal",
      quantity_available: 3,
      estimated_production_date: nil,
      estimated_arrival_date: nil,
      last_synced_at: Time.current
    )

    result = ForecastManualSyncService.new(report_type: :monthly).call
    imported_forecast = SupplyForecast.where(forecast_sync_run: result.sync_run).order(:source_line_no).first

    assert_nil imported_forecast.estimated_production_date
    assert_nil imported_forecast.estimated_arrival_date
  end

  test "daily import keeps the most complete stock timing data" do
    result = ForecastManualSyncService.new(report_type: :daily).call
    imported_forecasts = SupplyForecast.where(forecast_sync_run: result.sync_run)
    complete_forecast = imported_forecasts.find do |forecast|
      forecast.quantity_available.present? &&
        forecast.estimated_production_date.present? &&
        forecast.estimated_arrival_date.present?
    end

    assert_not_nil complete_forecast
  end

  test "daily sync leaves some rows unchanged when file has no new business updates" do
    result = ForecastManualSyncService.new(report_type: :daily).call

    unchanged_rows = SupplyForecast.where(forecast_sync_run: result.sync_run).last_sync_change_kind_unchanged
    assert_predicate unchanged_rows, :exists?
  end
end
