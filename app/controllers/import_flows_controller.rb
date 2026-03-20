class ImportFlowsController < ApplicationController
  REPORT_TYPES = %w[daily weekly monthly].freeze

  before_action :redirect_sales_mode_to_stock_workspace
  before_action :redirect_auto_sync_flow_to_forecasts

  def show
    @current_report_type = normalized_report_type
    reset_demo_baseline_if_needed
    @latest_import_run = ForecastSyncRun.status_completed.where(source_report_type: @current_report_type).order(started_at: :desc).first
    @import_rows = SupplyForecast.active_feed.where(source_report_type: @current_report_type).order(:source_batch_key, :source_line_no).limit(8)
    @import_batches = @import_rows.group_by(&:source_batch_key)
    @ordered_count = @import_rows.count { |forecast| forecast.stock_plan_item&.status_ordered? }
    @incoming_count = @import_rows.count { |forecast| forecast.stock_plan_item&.status_incoming? }
  end

  def import
    report_type = normalized_report_type
    sleep 1.1 if Rails.env.development?
    result = ForecastManualSyncService.new(report_type: report_type).call
    session[:preserve_imported_feed_once] = report_type

    notice = [
      "#{report_type.titleize} file imported",
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

  def normalized_report_type
    REPORT_TYPES.include?(params[:report_type].to_s) ? params[:report_type] : "daily"
  end

  def reset_demo_baseline_if_needed
    return unless Rails.env.development?
    return if preserve_imported_view_once?

    DemoForecastBaselineService.call
  end

  def preserve_imported_view_once?
    session.delete(:preserve_imported_feed_once) == @current_report_type
  end
end
