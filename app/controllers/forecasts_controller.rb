class ForecastsController < ApplicationController
  REPORT_TYPES = %w[daily weekly monthly].freeze

  def index
    @current_report_type = normalized_report_type
    reset_demo_baseline_if_needed
    @query = params[:q].to_s.strip
    @latest_sync_run = ForecastSyncRun.status_completed.where(source_report_type: @current_report_type).order(started_at: :desc).first
    @forecasts = SupplyForecast.active_feed.includes(stock_plan_item: :stock_plan).where(source_report_type: @current_report_type)
    @forecasts = apply_search(@forecasts)
    @forecasts = @forecasts.order(:source_batch_key, :source_line_no)
    @forecast_batches = @forecasts.group_by(&:source_batch_key)
  end

  def sync
    report_type = normalized_report_type
    sleep 1.1 if Rails.env.development?
    result = ForecastManualSyncService.new(report_type: report_type).call
    session[:preserve_synced_forecasts_once] = report_type

    notice = [
      "#{report_type.titleize} sync completed",
      "#{result.inserted} new",
      "#{result.updated} updated",
      "#{result.archived} archived"
    ].join(" • ")

    redirect_to forecasts_path(report_type: report_type), notice: notice
  end

  private

  def normalized_report_type
    REPORT_TYPES.include?(params[:report_type].to_s) ? params[:report_type] : "daily"
  end

  def reset_demo_baseline_if_needed
    return unless Rails.env.development?
    return if preserve_synced_view_once?

    DemoForecastBaselineService.call
  end

  def preserve_synced_view_once?
    session.delete(:preserve_synced_forecasts_once) == @current_report_type
  end

  def apply_search(scope)
    return scope if @query.blank?

    term = "%#{ActiveRecord::Base.sanitize_sql_like(@query.downcase)}%"
    scope.where(
      "LOWER(COALESCE(model_label, '')) LIKE :term OR LOWER(COALESCE(model_code, '')) LIKE :term OR LOWER(COALESCE(grade, '')) LIKE :term",
      term:
    )
  end
end
