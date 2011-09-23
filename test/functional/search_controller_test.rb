require 'test_helper'

class SearchControllerTest < ActionController::TestCase

  test 'GET search which raises VacancySearch::LocationMissing' do
    VacancySearch.expects(:new).raises(VacancySearch::LocationMissing)
    get :show
    assert_redirected_to root_path
  end

  test 'GET search which raises a VacancySearch::SearchError' do
    VacancySearch.expects(:new).raises(VacancySearch::SearchError)
    get :show
    assert_response 500
  end

  test 'GET search which is a success' do
    mock_results = mock()
    mock_results.stubs(:total => 0)

    mock_search = mock()
    mock_search.stubs(:run => mock_results, :query_params => {}, :location => "postcode", :query => "machine")

    VacancySearch.expects(:new).returns(mock_search)

    get :show
    assert_response :success
  end

end