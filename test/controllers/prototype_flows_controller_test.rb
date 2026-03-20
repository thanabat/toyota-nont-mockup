require "test_helper"

class PrototypeFlowsControllerTest < ActionDispatch::IntegrationTest
  test "should switch to import file flow and redirect back" do
    patch prototype_flow_url, params: { flow: :import_file, return_to: "/import_flow" }

    assert_redirected_to "/import_flow"

    get root_url
    assert_response :success
    assert_select "h2", /Import File Flow/
    assert_select "span", text: /กำลังใช้งาน/, count: 1
  end

  test "should reset demo state when entering import file flow from landing" do
    patch prototype_flow_url, params: { flow: :import_file, return_to: "/import_flow" }
    post import_flow_import_url

    patch prototype_flow_url, params: { flow: :import_file, reset_demo: true, return_to: "/import_flow" }
    follow_redirect!

    assert_response :success
    assert_select "p", /ยังไม่มีข้อมูลนำเข้าใน session นี้/
    assert_select "p", /ยังไม่มีข้อมูลนำเข้า/
  end
end
