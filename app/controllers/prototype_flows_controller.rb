class PrototypeFlowsController < ApplicationController
  def update
    session[:prototype_flow] = params[:flow].presence_in(%w[auto_sync import_file]) || "auto_sync"

    redirect_to safe_return_path
  end

  private

  def safe_return_path
    return_path = params[:return_to].presence
    return root_path if return_path.blank? || return_path.start_with?("http")

    return_path
  end
end
