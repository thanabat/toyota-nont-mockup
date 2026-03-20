class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :ensure_workspace_mode
  before_action :ensure_prototype_flow

  helper_method :current_workspace_mode, :allocation_mode?, :sales_mode?,
                :current_prototype_flow, :auto_sync_flow?, :import_file_flow?

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

  def current_prototype_flow
    session[:prototype_flow].presence_in(%w[auto_sync import_file]) || "auto_sync"
  end

  def auto_sync_flow?
    current_prototype_flow == "auto_sync"
  end

  def import_file_flow?
    current_prototype_flow == "import_file"
  end

  def ensure_prototype_flow
    session[:prototype_flow] = current_prototype_flow
  end
end
