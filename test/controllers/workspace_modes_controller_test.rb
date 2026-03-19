require "test_helper"

class WorkspaceModesControllerTest < ActionDispatch::IntegrationTest
  test "should switch to sales mode and redirect back" do
    patch workspace_mode_url, params: { mode: :sales, return_to: "/stock_orders" }

    assert_redirected_to "/stock_orders"

    get stock_orders_url
    assert_response :success
    assert_select "p", /Sales Workspace/
  end
end
