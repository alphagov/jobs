# coding:utf-8

require 'test_helper'

class JobTest < ActiveSupport::TestCase
  include AssetHelpers

  test 'is invalid without a vacancy_id' do
    job = Factory.build(:job, :vacancy_id => nil)
    assert_equal false, job.valid?
  end

  test '.to_solr_document' do
    job = Factory.build(:job,
      :vacancy_id => "TES/1234",
      :vacancy_title => "Testing Job",
      :soc_code => "1234",
      :latitude => 51.0,
      :longitude => 1.0,
      :location_name => "Testing Town, County",
      :is_permanent => true,
      :hours => 25,
      :hours_display_text => "25 hours, flexible working",
      :wage_display_text => "Lots of cash",
      :vacancy_description => "Work for us",
      :employer_name => "Alphagov",
      :how_to_apply => "Send us an email",
      :received_on => Date.today
    )

    document = DelSolr::Document.new
    document.add_field 'id', "TES/1234"
    document.add_field 'title', "Testing Job", :cdata => true
    document.add_field 'soc_code', '1234'
    document.add_field 'location', [51.0, 1.0].join(",")
    document.add_field 'location_name', "Testing Town, County", :cdata => true
    document.add_field 'is_permanent', true
    document.add_field 'hours', 25
    document.add_field 'hours_display_text', "25 hours, flexible working", :cdata => true
    document.add_field 'wage_display_text', "Lots of cash", :cdata => true
    document.add_field 'received_on', Date.today.beginning_of_day.iso8601
    document.add_field 'vacancy_description', "Work for us", :cdata => true
    document.add_field 'employer_name', "Alphagov", :cdata => true
    document.add_field 'how_to_apply', 'Send us an email', :cdata => true

    assert_equal job.to_solr_document.xml, document.xml
  end

  test '.send_to_solr' do
    job = Factory.build(:job)
    job.stubs(:to_solr_document).returns(mock())
    $solr.expects(:update).with(job.to_solr_document).returns(true)
    assert_equal true, job.send_to_solr
  end

  test '.send_to_solr!' do
    job = Factory.build(:job)
    job.stubs(:to_solr_document).returns(mock())
    $solr.expects(:update!).with(job.to_solr_document).returns(true)
    assert_equal true, job.send_to_solr!
  end

  test '.delete_from_solr' do
    job = Factory.build(:job)
    $solr.expects(:delete).with(job.vacancy_id).returns(true)
    assert_equal true, job.delete_from_solr
  end

  test '.fetch_details_from_api' do
    job = Factory.create(:job, :vacancy_id => "SOM/56416")

    stub_request(:get, "http://soap.xbswebservices.info/jobsearch.asmx?WSDL").
      to_return(:status => 200, :body => asset_contents('jobsearch_wsdl'))

    stub_request(:post, "http://soap.xbswebservices.info/jobsearch.asmx").
      with(:body => asset_contents('get_job_detail_request')).
      to_return(:body => asset_contents('get_job_detail_response'))

    details = job.fetch_details_from_api

    # just to prove we're getting the hash back
    assert_equal details[:age_exempt], "N"
  end

  test '#fetch_vacancies_from_api' do
    # stub WSDL
    stub_request(:get, "http://soap.xbswebservices.info/jobsearch.asmx?WSDL").
      to_return(:status => 200, :body => asset_contents('jobsearch_wsdl'))

    stub_request(:post, "http://soap.xbswebservices.info/jobsearch.asmx").
      with(:body => asset_contents('all_near_me_request')).
      to_return(:body => asset_contents('all_near_me_response'))

    response = Job.fetch_vacancies_from_api(51.0, 1.0)
    assert_equal 100, response.length
  end

  test '#import_for_point' do
    stub_vacancy = {:currency=>"GBP", :date_received=>"30082011", :distance_sort_order_id=>"2396.97008934328", :es_vacancy=>"Y", :hours=>"35", :hours_display_text=>"37.5 HOURS OVER 5 DAYS", :hours_qualifier=>"per week", :is_national=>false, :is_regional=>false, :location=>{:distance_from_origin=>"2396.97008934328", :latitude=>"50.986008297409", :longitude=>"0.9740371746526", :origin_latitude=>"51", :origin_longitude=>"1", :location_name=>"NEW ROMNEY, KENT"}, :location_display_text=>"NEW ROMNEY, KENT", :order_id=>"1", :perm_temp=>"P", :quality=>"86", :received_on=> Time.utc(2011, 8, 30, 0, 0, 0), :soc_code=>"3543", :vacancy_detail=>{:hours=>"0", :soc_code=>"0"}, :vacancy_id=>"FOK/12116", :vacancy_title=>"CHARITY FUNDRAISER", :wage=>"See details", :wage_display_text=>"£255 TO £1000 PER WEEK", :wage_qualifier=>"NK", :wage_sort_order_id=>"20"}

    job = stub_everything('job', :new_record? => true)
    job.expects(:vacancy_title=).with(stub_vacancy[:vacancy_title])
    job.expects(:received_on=).with(stub_vacancy[:received_on])
    job.expects(:soc_code=).with(stub_vacancy[:soc_code])
    job.expects(:wage=).with(stub_vacancy[:wage])
    job.expects(:wage_qualifier=).with(stub_vacancy[:wage_qualifier])
    job.expects(:wage_display_text=).with(stub_vacancy[:wage_display_text])
    job.expects(:currency=).with(stub_vacancy[:currency])
    job.expects(:is_national=).with(stub_vacancy[:is_national])
    job.expects(:is_regional=).with(stub_vacancy[:is_regional])
    job.expects(:hours=).with(stub_vacancy[:hours].to_i)
    job.expects(:hours_qualifier=).with(stub_vacancy[:hours_qualifier])
    job.expects(:hours_display_text=).with(stub_vacancy[:hours_display_text])
    job.expects(:location_name=).with(stub_vacancy[:location][:location_name])
    job.expects(:latitude=).with(stub_vacancy[:location][:latitude].to_f)
    job.expects(:longitude=).with(stub_vacancy[:location][:longitude].to_f)
    job.expects(:is_permanent=).with(true)

    job.expects(:import_details!).once
    job.expects(:save!).once

    Job.stubs(:fetch_vacancies_from_api).returns([stub_vacancy])
    Job.stubs(:find_or_initialize_by_vacancy_id).with('FOK/12116').returns(job)
    Job.import_for_point(51.0, 1.0)
  end

end