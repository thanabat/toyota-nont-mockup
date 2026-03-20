class DemoResetsController < ApplicationController
  def create
    DemoForecastBaselineService.call if Rails.env.development?

    session.delete(:preserve_imported_feed_once)
    session.delete(:preserve_synced_forecasts_once)
    session.delete(:latest_import_report_type)
    session.delete(:import_flow_initialized)
    session.delete(:first_import_badge_report_type)

    redirect_to safe_return_path, notice: "รีเซ็ต demo data และ flow แล้ว"
  end

  private

  def safe_return_path
    path = params[:return_to].to_s
    return root_path unless path.start_with?("/")

    path
  end
end
