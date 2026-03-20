require "test_helper"

class DemoResetsControllerTest < ActionDispatch::IntegrationTest
  test "should reset import flow session state and redirect back" do
    patch prototype_flow_url, params: { flow: :import_file, return_to: "/import_flow" }
    post import_flow_import_url

    post demo_reset_url, params: { return_to: "/import_flow" }

    assert_redirected_to "/import_flow"

    follow_redirect!
    assert_response :success
    assert_select "p", /ยังไม่มีข้อมูลนำเข้าใน session นี้/
    assert_select "p", /ยังไม่มีข้อมูลนำเข้า/
  end
end
