require 'test_helper'

class JobSearchTest < ActiveSupport::TestCase
  test 'initialized without any options' do
    assert_raise(VacancySearch::LocationMissing) { VacancySearch.new({}).run }
  end

  test 'initialized with XOR latitude, longitude' do
    assert_raise(VacancySearch::LocationMissing) { VacancySearch.new(:latitude => 51.0).run }
    assert_raise(VacancySearch::LocationMissing) { VacancySearch.new(:longitude => 1.0).run }
  end

  test 'initialized with a longitude and a latitude' do
    js = VacancySearch.new(:latitude => 51.0, :longitude => 1.0)
    assert_equal 51.0, js.latitude
    assert_equal 1.0, js.longitude
  end

  test 'initialized with a location' do
    js = VacancySearch.new(:location => "Oxford")
    assert_equal "Oxford", js.location
  end

  test 'initialized with a location, XOR latitude, longitude' do
    assert_raise(VacancySearch::InvalidLocationCombination) { VacancySearch.new(:latitude => 51.0, :location => "Oxford").run }
    assert_raise(VacancySearch::InvalidLocationCombination) { VacancySearch.new(:longitude => 1.0, :location => "Oxford").run }
  end

  test 'initialized with only latitude/longitude' do
    js = VacancySearch.new(:latitude => 51.0, :longitude => 1.0)
    assert_equal 50, js.per_page
    assert_equal 1, js.page
    assert_nil js.query
    assert_nil js.permanent
    assert_nil js.full_time
  end

  test 'initialized with the permanent option set true' do
    js = VacancySearch.new(:latitude => 51.0, :longitude => 1.0, :permanent => true)
    assert_equal true, js.permanent
  end

  test 'initialized with the full_time option set true' do
    js = VacancySearch.new(:latitude => 51.0, :longitude => 1.0, :full_time => true)
    assert_equal true, js.full_time
  end

  default_latitude = 51.0
  default_longitude = 1.0
  default_params = {
    :query => "*:*",
    :fields => "*",
    :fq => "{!bbox}",
    :sort => 'geodist() asc',
    :sfield => 'location',
    :d => 80.4672, # 50 miles in km
    :pt => '51.0,1.0',
    :limit => 50,
    :offset => 0,
    :filters => []
  }

  test '.run when no options are set' do
    js = VacancySearch.new(:latitude => default_latitude, :longitude => default_longitude)
    $solr.expects(:query).with('standard', default_params).returns(true)
    js.run
  end

  test '.run when the permanent option is true' do
    js = VacancySearch.new(:latitude => default_latitude, :longitude => default_longitude, :permanent => true)
    params = default_params.merge({ :filters => [{ :is_permanent => true }] })
    $solr.expects(:query).with('standard', params).returns(true)
    js.run
  end

  test '.run when the permanent option is false' do
    js = VacancySearch.new(:latitude => default_latitude, :longitude => default_longitude, :permanent => false)
    params = default_params.merge({ :filters => [{ :is_permanent => false }] })
    $solr.expects(:query).with('standard', params).returns(true)
    js.run
  end

  test '.run when the full_time option is true' do
    js = VacancySearch.new(:latitude => default_latitude, :longitude => default_longitude, :full_time => true)
    params = default_params.merge({ :filters => ["hours:[30 TO *]"] })
    $solr.expects(:query).with('standard', params).returns(true)
    js.run
  end

  test '.run when the full_time option is false' do
    js = VacancySearch.new(:latitude => default_latitude, :longitude => default_longitude, :full_time => false)
    params = default_params.merge({ :filters => ["hours:[* TO 29]"] })
    $solr.expects(:query).with('standard', params).returns(true)
    js.run
  end

  test '.run when the query returns nil' do
    # this indicates that the DelSolr library has failed to contact Solr
    $solr.expects(:query).returns(nil)
    js = VacancySearch.new(:latitude => 51.0, :longitude => 1.0)
    assert_raise(VacancySearch::SearchError) { js.run }
  end

  test '.query_params when only latitude and longitude are set' do
    js = VacancySearch.new(:latitude => 51.0, :longitude => 1.0)
    qp = { :latitude => 51.0, :longitude => 1.0 }
    assert_equal qp, js.query_params
  end

  test '.query_params when only location is set' do
    js = VacancySearch.new(:location => "Oxford")
    qp = { :location => "Oxford" }
    assert_equal qp, js.query_params
  end

  test '#find_individual which is found' do
    expected_params = {
      :query => "*:*",
      :fields => "*",
      :filters => ["id:JOB/1234"],
      :limit => 1
    }

    doc = {
      'id' => 'JOB/1234'
    }
    mock_response = mock()
    mock_response.stubs(:docs).returns([doc])

    $solr.expects(:query).with('standard', expected_params).returns(mock_response)
    assert_equal VacancySearch.find_individual('JOB/1234'), doc
  end

  test '#find_individual which is not found' do
    expected_params = {
      :query => '*:*',
      :fields => '*',
      :filters => ["id:JOB/1234"],
      :limit => 1
    }

    mock_response = mock()
    mock_response.stubs(:docs).returns([])

    $solr.expects(:query).with('standard', expected_params).returns(mock_response)
    assert_equal VacancySearch.find_individual('JOB/1234'), nil
  end
end