manual_run = ForecastSyncRun.find_or_create_by!(started_at: Time.zone.parse("2026-03-19 09:00:00")) do |run|
  run.trigger_mode = :manual
  run.source_report_type = :daily
  run.status = :completed
  run.initiated_by = "allocation.team"
  run.completed_at = Time.zone.parse("2026-03-19 09:05:00")
  run.records_processed = 3
  run.records_inserted = 3
end

[
  {
    source_key: "FC-20260319-001",
    source_report_type: :daily,
    model_code: "YARIS-ATIV",
    model_label: "Yaris Ativ Sport Premium",
    grade: "Sport Premium",
    color_code: "089",
    color_name: "Platinum White Pearl",
    quantity_available: 6,
    estimated_production_date: Date.new(2026, 3, 25),
    estimated_arrival_date: Date.new(2026, 4, 2)
  },
  {
    source_key: "FC-20260319-002",
    source_report_type: :weekly,
    model_code: "HILUX-REVO",
    model_label: "Hilux Revo Prerunner",
    grade: "2.4 Entry",
    color_code: "1D6",
    color_name: "Silver Metallic",
    quantity_available: 4,
    estimated_production_date: Date.new(2026, 3, 29),
    estimated_arrival_date: Date.new(2026, 4, 6)
  },
  {
    source_key: "FC-20260319-003",
    source_report_type: :monthly,
    model_code: "COROLLA-CROSS",
    model_label: "Corolla Cross HEV Premium",
    grade: "HEV Premium",
    color_code: "3U5",
    color_name: "Red Mica Metallic",
    quantity_available: 2,
    estimated_production_date: Date.new(2026, 4, 8),
    estimated_arrival_date: Date.new(2026, 4, 18)
  }
].each do |forecast|
  SupplyForecast.find_or_create_by!(source_key: forecast[:source_key]) do |record|
    record.forecast_sync_run = manual_run
    record.source_report_type = forecast[:source_report_type]
    record.model_code = forecast[:model_code]
    record.model_label = forecast[:model_label]
    record.grade = forecast[:grade]
    record.color_code = forecast[:color_code]
    record.color_name = forecast[:color_name]
    record.quantity_available = forecast[:quantity_available]
    record.estimated_production_date = forecast[:estimated_production_date]
    record.estimated_arrival_date = forecast[:estimated_arrival_date]
    record.source_generated_on = Date.new(2026, 3, 19)
    record.last_synced_at = Time.zone.parse("2026-03-19 09:05:00")
  end
end

plan = StockPlan.find_or_create_by!(plan_no: "SP-20260319-001") do |stock_plan|
  stock_plan.plan_type = :target_driven
  stock_plan.status = :confirmed
  stock_plan.requested_by = "allocation.team"
  stock_plan.title = "Initial April stock intake"
  stock_plan.confirmed_at = Time.zone.parse("2026-03-19 10:00:00")
  stock_plan.note = "Prototype seed for allocation planning"
end

selected_forecast = SupplyForecast.find_by!(source_key: "FC-20260319-001")
StockPlanItem.find_or_create_by!(stock_plan: plan, supply_forecast: selected_forecast) do |item|
  item.selected_quantity = 4
  item.note = "Selected for initial stock build-up"
end
