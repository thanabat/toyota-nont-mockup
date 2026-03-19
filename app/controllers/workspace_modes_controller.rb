class WorkspaceModesController < ApplicationController
  def update
    session[:workspace_mode] = params[:mode].presence_in(%w[allocation sales]) || "allocation"

    redirect_to safe_return_path
  end

  private

  def safe_return_path
    path = params[:return_to].to_s
    return root_path unless path.start_with?("/")

    path
  end
end
