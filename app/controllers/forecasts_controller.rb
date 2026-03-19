class ForecastsController < ApplicationController
  REPORT_TYPES = %w[daily weekly monthly].freeze

  def index
    @current_report_type = normalized_report_type
    reset_demo_baseline_if_needed
    @latest_sync_run = ForecastSyncRun.status_completed.where(source_report_type: @current_report_type).order(started_at: :desc).first
    @forecasts = SupplyForecast.active_feed.where(source_report_type: @current_report_type).order(:source_batch_key, :source_line_no)
    @forecast_batches = @forecasts.group_by(&:source_batch_key)
    @summary = {
      total_lines: @forecasts.count,
      total_batches: @forecast_batches.count,
      available_lines: @forecasts.status_available.count,
      selected_lines: @forecasts.status_selected.count,
      changed_lines: @forecasts.status_changed_after_selection.count,
      new_lines: @latest_sync_run.present? ? @forecasts.where(forecast_sync_run: @latest_sync_run).last_sync_change_kind_inserted.count : 0,
      updated_lines: @latest_sync_run.present? ? @forecasts.where(forecast_sync_run: @latest_sync_run).last_sync_change_kind_updated.count : 0
    }
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
end
