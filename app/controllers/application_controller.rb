class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :ensure_workspace_mode

  helper_method :current_workspace_mode, :allocation_mode?, :sales_mode?

  private

  def current_workspace_mode
    session[:workspace_mode].presence_in(%w[allocation sales]) || "allocation"
  end

  def allocation_mode?
    current_workspace_mode == "allocation"
  end

  def sales_mode?
    current_workspace_mode == "sales"
  end

  def ensure_workspace_mode
    session[:workspace_mode] = current_workspace_mode
  end
end
