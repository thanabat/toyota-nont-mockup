require "test_helper"

class SupplyForecastTest < ActiveSupport::TestCase
  setup do
    @sync_run = ForecastSyncRun.create!(
      started_at: Time.current,
      trigger_mode: :manual,
      source_report_type: :daily,
      status: :completed
    )
  end

  test "source_key must be unique" do
    SupplyForecast.create!(
      forecast_sync_run: @sync_run,
      source_key: "FORECAST-001",
      source_batch_key: "BATCH-001",
      source_line_no: 1,
      source_report_type: :daily,
      model_code: "YARIS-ATIV",
      quantity_available: 3,
      last_synced_at: Time.current
    )

    duplicate = SupplyForecast.new(
      forecast_sync_run: @sync_run,
      source_key: "FORECAST-001",
      source_batch_key: "BATCH-001",
      source_line_no: 2,
      source_report_type: :daily,
      model_code: "COROLLA-CROSS",
      quantity_available: 2,
      last_synced_at: Time.current
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:source_key], "has already been taken"
  end

  test "apply_sync marks selected forecasts as changed when tracked data changes" do
    forecast = SupplyForecast.create!(
      forecast_sync_run: @sync_run,
      source_key: "FORECAST-002",
      source_batch_key: "BATCH-002",
      source_line_no: 1,
      source_report_type: :daily,
      model_code: "HILUX-REVO",
      quantity_available: 4,
      last_synced_at: Time.current
    )
    plan = StockPlan.create!(plan_no: "SP-TEST-001", requested_by: "allocation.team")
    StockPlanItem.create!(stock_plan: plan, supply_forecast: forecast, selected_quantity: 2)

    forecast.apply_sync!(
      {
        source_report_type: :daily,
        source_batch_key: "BATCH-002",
        source_line_no: 1,
        model_code: "HILUX-REVO",
        quantity_available: 5
      },
      forecast_sync_run: @sync_run
    )

    assert_predicate forecast, :status_changed_after_selection?
    assert_equal 5, forecast.quantity_available
    assert_not_nil forecast.change_detected_at
  end

  test "apply_sync treats metadata-only refresh as unchanged" do
    forecast = SupplyForecast.create!(
      forecast_sync_run: @sync_run,
      source_key: "FORECAST-003",
      source_batch_key: "BATCH-003",
      source_line_no: 1,
      source_report_type: :daily,
      model_code: "CAMRY",
      model_label: "Camry HEV Premium Luxury",
      quantity_available: 2,
      estimated_production_date: Date.current + 7.days,
      estimated_arrival_date: Date.current + 14.days,
      last_synced_at: Time.current
    )

    forecast.apply_sync!(
      {
        source_report_type: :daily,
        source_batch_key: "BATCH-004",
        source_line_no: 9,
        source_generated_on: Date.current,
        model_code: "CAMRY",
        model_label: "Camry HEV Premium Luxury",
        quantity_available: 2,
        estimated_production_date: forecast.estimated_production_date,
        estimated_arrival_date: forecast.estimated_arrival_date
      },
      forecast_sync_run: @sync_run
    )

    assert_predicate forecast, :last_sync_change_kind_unchanged?
    assert_predicate forecast, :status_available?
  end
end
