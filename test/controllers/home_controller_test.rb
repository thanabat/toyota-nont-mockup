require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get root_url

    assert_response :success
    assert_select "h1", /เลือกแนวคิดที่ต้องการนำเสนอ/
    assert_select "h2", /Auto Sync Flow/
    assert_select "h2", /Import File Flow/
    assert_select "button", /เข้า Idea 01/
    assert_select "button", /เข้า Idea 02/
  end

  test "should reflect sales mode on home" do
    patch workspace_mode_url, params: { mode: :sales, return_to: "/" }
    get root_url

    assert_response :success
    assert_select "h2", /Auto Sync Flow/
    assert_select "button", /เข้า Idea 01/
    assert_select "a", text: /Forecast/, count: 0
  end

  test "should reflect import file flow on home" do
    patch prototype_flow_url, params: { flow: :import_file, return_to: "/" }
    get root_url

    assert_response :success
    assert_select "h2", /Import File Flow/
    assert_select "span", text: /กำลังใช้งาน/, count: 1
  end
end
