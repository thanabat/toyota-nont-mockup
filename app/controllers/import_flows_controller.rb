class ImportFlowsController < ApplicationController
  REPORT_TYPES = %w[daily weekly monthly].freeze
  IMPORT_SEQUENCE = %w[monthly weekly daily].freeze

  before_action :redirect_sales_mode_to_stock_workspace
  before_action :redirect_auto_sync_flow_to_forecasts

  def show
    reset_demo_baseline_if_needed
    @import_initialized = import_initialized?
    @current_report_type = latest_report_type
    @next_report_type = next_report_type
    @latest_import_run = latest_import_run
    @first_import_presentation = session[:first_import_badge_report_type] == @current_report_type
    @previous_report_type = previous_report_type(@current_report_type)

    if @import_initialized
      @import_rows = SupplyForecast.active_feed.where(source_report_type: @current_report_type).order(:source_batch_key, :source_line_no).limit(8)
      @import_batches = @import_rows.group_by(&:source_batch_key)
      @previous_feed_lookup = previous_feed_lookup(@previous_report_type)
      build_import_result_summary
    else
      @import_rows = []
      @import_batches = {}
      @previous_feed_lookup = {}
      @new_count = 0
      @updated_count = 0
      @unchanged_count = 0
    end
  end

  def import
    first_import = !import_initialized?
    report_type = next_report_type
    sleep 1.1 if Rails.env.development?
    result = ForecastManualSyncService.new(report_type: report_type).call
    stage_label = view_context.import_stage_label(report_type)
    session[:import_flow_initialized] = true
    session[:preserve_imported_feed_once] = report_type
    session[:latest_import_report_type] = report_type
    session[:first_import_badge_report_type] = report_type if first_import

    notice = [
      "นำเข้าไฟล์ #{stage_label} แล้ว",
      "#{result.updated} updated",
      "#{result.inserted} new",
      "#{result.archived} archived",
      "#{result.promoted_to_incoming} moved to incoming"
    ].join(" • ")

    redirect_to import_flow_path(report_type: report_type), notice: notice
  end

  private

  def redirect_sales_mode_to_stock_workspace
    return unless sales_mode?

    redirect_to stock_orders_path(tab: :incoming), alert: "ฝ่ายขายใช้งานผ่านหน้า Stock กำลังเข้าเป็นหลัก"
  end

  def redirect_auto_sync_flow_to_forecasts
    return if import_file_flow?

    redirect_to forecasts_path, alert: "Auto Sync Flow ใช้งานผ่านหน้า Forecast เป็นหลัก"
  end

  def latest_report_type
    return available_report_types.first || "monthly" unless import_initialized?

    preferred = session[:latest_import_report_type].presence_in(available_report_types)
    preferred || available_report_types.first || "monthly"
  end

  def next_report_type
    report_type = params[:feed_type].presence_in(REPORT_TYPES)
    return report_type if report_type.present?

    types = available_report_types
    return "monthly" if types.empty?

    last_imported_type = session[:latest_import_report_type].presence_in(types)
    return latest_report_type if last_imported_type.blank?

    index = types.index(last_imported_type) || 0
    types[(index + 1) % types.length]
  end

  def available_report_types
    @available_report_types ||= begin
      detected_types = SupplyForecast.active_feed.distinct.order(:source_report_type).pluck(:source_report_type)
      ordered_types = IMPORT_SEQUENCE.select { |type| detected_types.include?(type) }
      ordered_types.presence || IMPORT_SEQUENCE
    end
  end

  def reset_demo_baseline_if_needed
    return unless Rails.env.development?
    return if preserve_imported_view_once?

    DemoForecastBaselineService.call
  end

  def preserve_imported_view_once?
    session.delete(:preserve_imported_feed_once) == latest_report_type
  end

  def import_initialized?
    session[:import_flow_initialized] == true
  end

  def latest_import_run
    return nil unless import_initialized?

    ForecastSyncRun.status_completed.where(source_report_type: @current_report_type).order(started_at: :desc).first
  end

  def previous_report_type(report_type)
    index = IMPORT_SEQUENCE.index(report_type)
    return nil if index.blank? || index.zero?

    IMPORT_SEQUENCE[index - 1]
  end

  def previous_feed_lookup(report_type)
    return {} if report_type.blank?

    SupplyForecast.active_feed.where(source_report_type: report_type).index_by do |forecast|
      view_context.import_comparison_key(forecast)
    end
  end

  def build_import_result_summary
    @new_count = 0
    @updated_count = 0
    @unchanged_count = 0

    @import_rows.each do |forecast|
      previous_forecast = @previous_feed_lookup[view_context.import_comparison_key(forecast)]
      result_label = view_context.import_result_label(
        forecast,
        force_new: @first_import_presentation,
        previous_forecast: previous_forecast
      )

      case result_label
      when "สร้างรายการใหม่"
        @new_count += 1
      when "อัปเดตข้อมูล"
        @updated_count += 1
      else
        @unchanged_count += 1
      end
    end
  end
end
