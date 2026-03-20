class PrototypeFlowsController < ApplicationController
  def update
    reset_demo_state! if ActiveModel::Type::Boolean.new.cast(params[:reset_demo])
    session[:prototype_flow] = params[:flow].presence_in(%w[auto_sync import_file]) || "auto_sync"

    redirect_to safe_return_path
  end

  private

  def reset_demo_state!
    DemoForecastBaselineService.call if Rails.env.development?

    session.delete(:preserve_imported_feed_once)
    session.delete(:preserve_synced_forecasts_once)
    session.delete(:latest_import_report_type)
    session.delete(:import_flow_initialized)
    session.delete(:first_import_badge_report_type)
  end

  def safe_return_path
    return_path = params[:return_to].presence
    return root_path if return_path.blank? || return_path.start_with?("http")

    return_path
  end
end
