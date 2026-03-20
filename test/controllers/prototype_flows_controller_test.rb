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
end
