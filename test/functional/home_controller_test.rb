require 'test_helper'

class HomeControllerTest < ActionController::TestCase

  test 'GET show' do
    get :show
    assert_response :success
  end

  test "should send slimmer analytics headers" do
    get :show
    assert_equal "Jobs",    @response.headers["X-Slimmer-Section"]
    assert_equal "125",     @response.headers["X-Slimmer-Need-ID"].to_s
    assert_equal "jobs",    @response.headers["X-Slimmer-Format"]
    assert_equal "citizen", @response.headers["X-Slimmer-Proposition"]
  end

end
