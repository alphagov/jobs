require 'test_helper'

class HomeControllerTest < ActionController::TestCase

  test 'GET show' do
    get :show
    assert_response :success
  end

end