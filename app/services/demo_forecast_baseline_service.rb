class DemoForecastBaselineService
  class << self
    def call
      new.call
    end
  end

  def call
    SalesInterest.delete_all
    StockPlanItem.delete_all
    StockPlan.delete_all
    SupplyForecast.delete_all
    ForecastSyncRun.delete_all

    sync_runs = SYNC_RUN_DEFINITIONS.transform_values do |attributes|
      ForecastSyncRun.create!(attributes)
    end

    FORECAST_ROWS.each do |row|
      sync_run = sync_runs.fetch(row[:sync_run_key])

      SupplyForecast.create!(
        source_batch_key: row[:source_batch_key],
        source_key: row[:source_key],
        source_line_no: row[:source_line_no],
        source_report_type: row[:source_report_type],
        model_code: row[:model_code],
        model_label: row[:model_label],
        grade: row[:grade],
        color_code: row[:color_code],
        color_name: row[:color_name],
        quantity_available: row[:quantity_available],
        estimated_production_date: row[:estimated_production_date],
        estimated_arrival_date: row[:estimated_arrival_date],
        source_generated_on: row[:source_generated_on],
        forecast_sync_run: sync_run,
        last_synced_at: sync_run.completed_at || sync_run.started_at,
        first_seen_at: sync_run.started_at,
        last_sync_change_kind: :inserted
      )
    end

    primary_plan = StockPlan.create!(
      plan_no: "SP-20260319-001",
      title: "Daily retail push",
      requested_by: "allocation.team",
      plan_type: :target_driven,
      status: :draft,
      note: "Baseline plan for daily retail allocation"
    )

    secondary_plan = StockPlan.create!(
      plan_no: "SP-20260319-002",
      title: "Weekly showroom fill",
      requested_by: "allocation.team",
      plan_type: :demand_driven,
      status: :draft,
      note: "Baseline plan for weekly showroom requests"
    )

    create_plan_item(primary_plan, "FC-WEEKLY-20260318-001-L1", 2, "Reserve for showroom stock fill")
    create_plan_item(secondary_plan, "FC-WEEKLY-20260318-001-L3", 1, "Requested by showroom Bang Bua Thong")
    create_plan_item(secondary_plan, "FC-MONTHLY-20260315-001-L1", 1, "Early hold for hybrid lead")

    changed_forecast = SupplyForecast.find_by!(source_key: "FC-WEEKLY-20260318-001-L3")
    auto_update_run = sync_runs.fetch(:auto_update_run)
    changed_forecast.apply_sync!(
      {
        source_batch_key: changed_forecast.source_batch_key,
        source_line_no: changed_forecast.source_line_no,
        source_report_type: changed_forecast.source_report_type,
        model_code: changed_forecast.model_code,
        model_label: changed_forecast.model_label,
        grade: changed_forecast.grade,
        color_code: changed_forecast.color_code,
        color_name: changed_forecast.color_name,
        quantity_available: changed_forecast.quantity_available + 1,
        estimated_production_date: changed_forecast.estimated_production_date + 2.days,
        estimated_arrival_date: Date.new(2026, 4, 8),
        source_generated_on: Date.new(2026, 3, 20)
      },
      forecast_sync_run: auto_update_run
    )

    seed_sales_interests
  end

  private

  def create_plan_item(plan, source_key, quantity, note)
    forecast = SupplyForecast.find_by!(source_key: source_key)
    StockPlanItem.create!(
      stock_plan: plan,
      supply_forecast: forecast,
      selected_quantity: quantity,
      note: note
    )
  end

  def seed_sales_interests
    create_sales_interest(
      "FC-MONTHLY-20260315-001-L1",
      sales_name: "กฤตภาส",
      branch_name: "โชว์รูมบางบัวทอง",
      status: :customer_waiting,
      note: "มีลูกค้ารอ Corolla Cross HEV สีแดง"
    )
    create_sales_interest(
      "FC-MONTHLY-20260315-001-L1",
      sales_name: "ชนินทร์",
      branch_name: "โชว์รูมรัตนาธิเบศร์",
      status: :watching,
      note: "ใช้เป็นตัวเลือกแทนกลุ่มลูกค้า SUV ไฮบริด"
    )
    create_sales_interest(
      "FC-WEEKLY-20260318-001-L3",
      sales_name: "นวพล",
      branch_name: "โชว์รูมปากเกร็ด",
      status: :watching,
      note: "ติดตาม Fortuner สีนี้ไว้สำหรับลูกค้าเดิม"
    )
  end

  def create_sales_interest(source_key, sales_name:, branch_name:, status:, note:)
    forecast = SupplyForecast.find_by!(source_key: source_key)
    item = forecast.stock_plan_item
    return if item.blank?

    SalesInterest.create!(
      stock_plan_item: item,
      sales_name:,
      branch_name:,
      status:,
      note:
    )
  end

  SYNC_RUN_DEFINITIONS = {
    daily_run: {
      started_at: Time.zone.parse("2026-03-19 09:00:00"),
      trigger_mode: :manual,
      source_report_type: :daily,
      status: :completed,
      initiated_by: "allocation.team",
      completed_at: Time.zone.parse("2026-03-19 09:05:00"),
      records_processed: 5,
      records_inserted: 5
    },
    weekly_run: {
      started_at: Time.zone.parse("2026-03-18 16:00:00"),
      trigger_mode: :manual,
      source_report_type: :weekly,
      status: :completed,
      initiated_by: "allocation.team",
      completed_at: Time.zone.parse("2026-03-18 16:07:00"),
      records_processed: 5,
      records_inserted: 5
    },
    monthly_run: {
      started_at: Time.zone.parse("2026-03-15 10:00:00"),
      trigger_mode: :manual,
      source_report_type: :monthly,
      status: :completed,
      initiated_by: "allocation.team",
      completed_at: Time.zone.parse("2026-03-15 10:20:00"),
      records_processed: 5,
      records_inserted: 5
    },
    auto_update_run: {
      started_at: Time.zone.parse("2026-03-20 07:00:00"),
      trigger_mode: :automatic,
      source_report_type: :weekly,
      status: :completed,
      initiated_by: "system",
      completed_at: Time.zone.parse("2026-03-20 07:02:00"),
      records_processed: 1,
      records_updated: 1
    }
  }.freeze

  FORECAST_ROWS = [
    {
      sync_run_key: :daily_run,
      source_batch_key: "FC-DAILY-20260319-001",
      source_key: "FC-DAILY-20260319-001-L1",
      source_line_no: 1,
      source_report_type: :daily,
      model_code: "YARIS-ATIV",
      model_label: "Yaris Ativ Sport Premium",
      grade: nil,
      color_code: "089",
      color_name: "Platinum White Pearl",
      quantity_available: nil,
      estimated_production_date: nil,
      estimated_arrival_date: nil,
      source_generated_on: Date.new(2026, 3, 19)
    },
    {
      sync_run_key: :daily_run,
      source_batch_key: "FC-DAILY-20260319-001",
      source_key: "FC-DAILY-20260319-001-L2",
      source_line_no: 2,
      source_report_type: :daily,
      model_code: "YARIS-ATIV",
      model_label: "Yaris Ativ Sport Premium",
      grade: nil,
      color_code: "1L0",
      color_name: "Attitude Black Mica",
      quantity_available: nil,
      estimated_production_date: nil,
      estimated_arrival_date: nil,
      source_generated_on: Date.new(2026, 3, 19)
    },
    {
      sync_run_key: :daily_run,
      source_batch_key: "FC-DAILY-20260319-001",
      source_key: "FC-DAILY-20260319-001-L3",
      source_line_no: 3,
      source_report_type: :daily,
      model_code: "YARIS-CROSS",
      model_label: "Yaris Cross HEV Premium Luxury",
      grade: nil,
      color_code: "1L0",
      color_name: "Attitude Black Mica",
      quantity_available: nil,
      estimated_production_date: nil,
      estimated_arrival_date: nil,
      source_generated_on: Date.new(2026, 3, 19)
    },
    {
      sync_run_key: :daily_run,
      source_batch_key: "FC-DAILY-20260319-001",
      source_key: "FC-DAILY-20260319-001-L4",
      source_line_no: 4,
      source_report_type: :daily,
      model_code: "YARIS-CROSS",
      model_label: "Yaris Cross HEV Premium Luxury",
      grade: nil,
      color_code: "1K3",
      color_name: "Urban Metal",
      quantity_available: nil,
      estimated_production_date: nil,
      estimated_arrival_date: nil,
      source_generated_on: Date.new(2026, 3, 19)
    },
    {
      sync_run_key: :daily_run,
      source_batch_key: "FC-DAILY-20260319-001",
      source_key: "FC-DAILY-20260319-001-L5",
      source_line_no: 5,
      source_report_type: :daily,
      model_code: "COROLLA-ALTIS",
      model_label: "Corolla Altis GR Sport",
      grade: nil,
      color_code: "040",
      color_name: "Super White",
      quantity_available: nil,
      estimated_production_date: nil,
      estimated_arrival_date: nil,
      source_generated_on: Date.new(2026, 3, 19)
    },
    {
      sync_run_key: :weekly_run,
      source_batch_key: "FC-WEEKLY-20260318-001",
      source_key: "FC-WEEKLY-20260318-001-L1",
      source_line_no: 1,
      source_report_type: :weekly,
      model_code: "HILUX-REVO",
      model_label: "Hilux Revo Prerunner",
      grade: "2.4 Entry",
      color_code: "1D6",
      color_name: "Silver Metallic",
      quantity_available: 4,
      estimated_production_date: Date.new(2026, 3, 29),
      estimated_arrival_date: nil,
      source_generated_on: Date.new(2026, 3, 18)
    },
    {
      sync_run_key: :weekly_run,
      source_batch_key: "FC-WEEKLY-20260318-001",
      source_key: "FC-WEEKLY-20260318-001-L2",
      source_line_no: 2,
      source_report_type: :weekly,
      model_code: "HILUX-REVO",
      model_label: "Hilux Revo Prerunner",
      grade: "2.4 Entry",
      color_code: "040",
      color_name: "Super White",
      quantity_available: 3,
      estimated_production_date: Date.new(2026, 3, 31),
      estimated_arrival_date: nil,
      source_generated_on: Date.new(2026, 3, 18)
    },
    {
      sync_run_key: :weekly_run,
      source_batch_key: "FC-WEEKLY-20260318-001",
      source_key: "FC-WEEKLY-20260318-001-L3",
      source_line_no: 3,
      source_report_type: :weekly,
      model_code: "FORTUNER",
      model_label: "Fortuner Legender",
      grade: "2.8 Legender 4WD",
      color_code: "218",
      color_name: "Phantom Brown",
      quantity_available: 2,
      estimated_production_date: Date.new(2026, 4, 1),
      estimated_arrival_date: nil,
      source_generated_on: Date.new(2026, 3, 18)
    },
    {
      sync_run_key: :weekly_run,
      source_batch_key: "FC-WEEKLY-20260318-001",
      source_key: "FC-WEEKLY-20260318-001-L4",
      source_line_no: 4,
      source_report_type: :weekly,
      model_code: "FORTUNER",
      model_label: "Fortuner Legender",
      grade: "2.8 Legender 4WD",
      color_code: "089",
      color_name: "Platinum White Pearl",
      quantity_available: 2,
      estimated_production_date: Date.new(2026, 4, 2),
      estimated_arrival_date: nil,
      source_generated_on: Date.new(2026, 3, 18)
    },
    {
      sync_run_key: :weekly_run,
      source_batch_key: "FC-WEEKLY-20260318-001",
      source_key: "FC-WEEKLY-20260318-001-L5",
      source_line_no: 5,
      source_report_type: :weekly,
      model_code: "VELOZ",
      model_label: "Veloz Premium",
      grade: "Premium CVT",
      color_code: "W09",
      color_name: "White Pearl",
      quantity_available: 4,
      estimated_production_date: Date.new(2026, 4, 2),
      estimated_arrival_date: nil,
      source_generated_on: Date.new(2026, 3, 18)
    },
    {
      sync_run_key: :monthly_run,
      source_batch_key: "FC-MONTHLY-20260315-001",
      source_key: "FC-MONTHLY-20260315-001-L1",
      source_line_no: 1,
      source_report_type: :monthly,
      model_code: "COROLLA-CROSS",
      model_label: "Corolla Cross HEV Premium",
      grade: "HEV Premium",
      color_code: "3U5",
      color_name: "Red Mica Metallic",
      quantity_available: 2,
      estimated_production_date: Date.new(2026, 4, 8),
      estimated_arrival_date: Date.new(2026, 4, 18),
      source_generated_on: Date.new(2026, 3, 15)
    },
    {
      sync_run_key: :monthly_run,
      source_batch_key: "FC-MONTHLY-20260315-001",
      source_key: "FC-MONTHLY-20260315-001-L2",
      source_line_no: 2,
      source_report_type: :monthly,
      model_code: "COROLLA-CROSS",
      model_label: "Corolla Cross HEV Premium",
      grade: "HEV Premium",
      color_code: "089",
      color_name: "Platinum White Pearl",
      quantity_available: 3,
      estimated_production_date: Date.new(2026, 4, 10),
      estimated_arrival_date: Date.new(2026, 4, 20),
      source_generated_on: Date.new(2026, 3, 15)
    },
    {
      sync_run_key: :monthly_run,
      source_batch_key: "FC-MONTHLY-20260315-001",
      source_key: "FC-MONTHLY-20260315-001-L3",
      source_line_no: 3,
      source_report_type: :monthly,
      model_code: "CAMRY",
      model_label: "Camry HEV Premium Luxury",
      grade: "HEV Premium Luxury",
      color_code: "1J9",
      color_name: "Precious Metal",
      quantity_available: 3,
      estimated_production_date: Date.new(2026, 4, 12),
      estimated_arrival_date: Date.new(2026, 4, 22),
      source_generated_on: Date.new(2026, 3, 15)
    },
    {
      sync_run_key: :monthly_run,
      source_batch_key: "FC-MONTHLY-20260315-001",
      source_key: "FC-MONTHLY-20260315-001-L4",
      source_line_no: 4,
      source_report_type: :monthly,
      model_code: "CAMRY",
      model_label: "Camry HEV Premium Luxury",
      grade: "HEV Premium Luxury",
      color_code: "1L0",
      color_name: "Attitude Black Mica",
      quantity_available: 2,
      estimated_production_date: Date.new(2026, 4, 14),
      estimated_arrival_date: Date.new(2026, 4, 24),
      source_generated_on: Date.new(2026, 3, 15)
    },
    {
      sync_run_key: :monthly_run,
      source_batch_key: "FC-MONTHLY-20260315-001",
      source_key: "FC-MONTHLY-20260315-001-L5",
      source_line_no: 5,
      source_report_type: :monthly,
      model_code: "INNOVA-ZENIX",
      model_label: "Innova Zenix HEV Smart",
      grade: "HEV Smart",
      color_code: "8W7",
      color_name: "Dark Steel Mica",
      quantity_available: 5,
      estimated_production_date: Date.new(2026, 4, 14),
      estimated_arrival_date: Date.new(2026, 4, 24),
      source_generated_on: Date.new(2026, 3, 15)
    }
  ].freeze
end
