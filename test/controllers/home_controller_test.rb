require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get root_url

    assert_response :success
    assert_select "a", /ดู Forecast/
    assert_select "a", /ดู Stock/
  end

  test "should reflect sales mode on home" do
    patch workspace_mode_url, params: { mode: :sales, return_to: "/" }
    get root_url

    assert_response :success
    assert_select "p", /Sales Mode/
    assert_select "a", /ดู Stock กำลังเข้า/
    assert_select "a", text: /Forecast/, count: 0
  end
end
