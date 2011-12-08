require 'test_helper'

class SearchControllerTest < ActionController::TestCase

  test 'GET search which raises VacancySearch::LocationMissing' do
    mock_search = create_search_mock
    mock_search.expects(:run).raises(VacancySearch::LocationMissing)
    VacancySearch.expects(:new).returns(mock_search)

    get :show
    assert_redirected_to root_path
  end

  test 'GET search which raises a VacancySearch::SearchError' do
    mock_search = create_search_mock
    mock_search.expects(:run).raises(VacancySearch::SearchError)
    VacancySearch.expects(:new).returns(mock_search)

    get :show
    assert_response 200
    assert_not_nil assigns[:formerrors][:location]
  end

  test 'GET search with an invalid location sets errors on the model' do
    mock_search = create_search_mock
    mock_search.expects(:run).raises(Geogov::UnrecognizedLocationError)
    VacancySearch.expects(:new).returns(mock_search)

    get :show, :location => 'nowhere'
    assert_response 200
    assert_not_nil assigns[:formerrors][:location]
  end

  test 'GET search which is a success' do
    mock_results = mock()
    mock_results.stubs(:total => 0)
    mock_search = create_search_mock
    mock_search.stubs(:run).returns(mock_results)
    VacancySearch.expects(:new).returns(mock_search)

    get :show
    assert_response :success
  end

  private
  def create_search_mock
    mock_search = mock()
    mock_search.stubs(:query_params => {}, :location => "postcode", :query => "machine", :total => 0, :docs => 0)
    mock_search
  end
end
