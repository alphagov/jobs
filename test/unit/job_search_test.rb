require 'test_helper'

class JobSearchTest < ActiveSupport::TestCase
  test 'initialized without any options' do
    assert_raise(JobSearch::LocationMissing) { JobSearch.new({}) }
  end

  test 'initialized with XOR latitude, longitude' do
    assert_raise(JobSearch::LocationMissing) { JobSearch.new(:latitude => 51.0) }
    assert_raise(JobSearch::LocationMissing) { JobSearch.new(:longitude => 1.0) }
  end

  test 'initialized with a longitude and a latitude' do
    js = JobSearch.new(:latitude => 51.0, :longitude => 1.0)
    assert_equal 51.0, js.latitude
    assert_equal 1.0, js.longitude
  end

  test 'initialized with a location' do
    js = JobSearch.new(:location => "Oxford")
    assert_equal "Oxford", js.location
  end

  test 'initialized with a location, XOR latitude, longitude' do
    assert_raise(JobSearch::InvalidLocationCombination) { JobSearch.new(:latitude => 51.0, :location => "Oxford") }
    assert_raise(JobSearch::InvalidLocationCombination) { JobSearch.new(:longitude => 1.0, :location => "Oxford") }
  end

  test 'initialized with only latitude/longitude' do
    js = JobSearch.new(:latitude => 51.0, :longitude => 1.0)
    assert_equal 50, js.per_page
    assert_equal "*:*", js.query
    assert_equal 1, js.page
    assert_nil js.permanent
    assert_nil js.full_time
  end

  test 'initialized with the permanent option set true' do
    js = JobSearch.new(:latitude => 51.0, :longitude => 1.0, :permanent => true)
    assert_equal true, js.permanent
  end

  test 'initialized with the full_time option set true' do
    js = JobSearch.new(:latitude => 51.0, :longitude => 1.0, :full_time => true)
    assert_equal true, js.full_time
  end

  default_latitude = 51.0
  default_longitude = 1.0
  default_params = {
    :query => "*:*",
    :fields => "*",
    :sort => 'geodist() asc',
    :sfield => 'location',
    :pt => '51.0,1.0',
    :limit => 50,
    :offset => 0,
    :filters => []
  }

  test '#run when no options are set' do
    js = JobSearch.new(:latitude => default_latitude, :longitude => default_longitude)
    $solr.expects(:query).with('standard', default_params).returns(true)
    js.run
  end

  test '#run when the permanent option is true' do
    js = JobSearch.new(:latitude => default_latitude, :longitude => default_longitude, :permanent => true)
    params = default_params.merge({ :filters => [{ :is_permanent => true }] })
    $solr.expects(:query).with('standard', params).returns(true)
    js.run
  end

  test '#run when the permanent option is false' do
    js = JobSearch.new(:latitude => default_latitude, :longitude => default_longitude, :permanent => false)
    params = default_params.merge({ :filters => [{ :is_permanent => false }] })
    $solr.expects(:query).with('standard', params).returns(true)
    js.run
  end

  test '#run when the full_time option is true' do
    js = JobSearch.new(:latitude => default_latitude, :longitude => default_longitude, :full_time => true)
    params = default_params.merge({ :filters => ["hours:[30 TO *]"] })
    $solr.expects(:query).with('standard', params).returns(true)
    js.run
  end

  test '#run when the full_time option is false' do
    js = JobSearch.new(:latitude => default_latitude, :longitude => default_longitude, :full_time => false)
    params = default_params.merge({ :filters => ["hours:[* TO 29]"] })
    $solr.expects(:query).with('standard', params).returns(true)
    js.run
  end

  test '#run when the query returns nil' do
    # this indicates that the DelSolr library has failed to contact Solr
    $solr.expects(:query).returns(nil)
    js = JobSearch.new(:latitude => 51.0, :longitude => 1.0)
    assert_raise(JobSearch::SearchError) { js.run }
  end

  test '#query_params when no options are set' do
    js = JobSearch.new(:latitude => 51.0, :longitude => 1.0)
    assert_equal Hash.new, js.query_params
  end

end