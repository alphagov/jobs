# coding:utf-8

require 'test_helper'

class VacancyTest < ActiveSupport::TestCase
  include AssetHelpers

  test 'is invalid without a vacancy_id' do
    vacancy = Factory.build(:vacancy, :vacancy_id => nil)
    assert_equal false, vacancy.valid?
  end

  test '.to_solr_document' do
    vacancy = Factory.build(:vacancy,
                            :vacancy_id => "TES/1234",
                            :vacancy_title => "Testing Vacancy",
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
    document.add_field 'title', "Testing Vacancy", :cdata => true
    document.add_field 'soc_code', '1234'
    document.add_field 'location', [51.0, 1.0].join(",")
    document.add_field 'location_name', "Testing Town, County", :cdata => true
    document.add_field 'is_permanent', true
    document.add_field 'hours', 25
    document.add_field 'hours_display_text', "25 hours, flexible working", :cdata => true
    document.add_field 'wage_display_text', "Lots of cash", :cdata => true
    document.add_field 'received_on', "#{Date.today.beginning_of_day.iso8601}Z"
    document.add_field 'vacancy_description', "Work for us", :cdata => true
    document.add_field 'employer_name', "Alphagov", :cdata => true
    document.add_field 'how_to_apply', 'Send us an email', :cdata => true
    document.add_field 'eligability_criteria', '', :cdata => true

    assert_equal document.xml, vacancy.to_solr_document.xml
  end

  test '.send_to_solr' do
    vacancy = Factory.build(:vacancy)
    vacancy.stubs(:to_solr_document).returns(mock())
    $solr.expects(:update).with(vacancy.to_solr_document).returns(true)
    assert_equal true, vacancy.send_to_solr
  end

  test '.send_to_solr!' do
    vacancy = Factory.build(:vacancy)
    vacancy.stubs(:to_solr_document).returns(mock())
    $solr.expects(:update!).with(vacancy.to_solr_document, :commitWithin => 300000).returns(true)
    assert_equal true, vacancy.send_to_solr!
  end

  test '.delete_from_solr' do
    vacancy = Factory.build(:vacancy)
    $solr.expects(:delete).with(vacancy.vacancy_id).returns(true)
    assert_equal true, vacancy.delete_from_solr
  end

  test '.fetch_details_from_api' do
    vacancy = Factory.create(:vacancy, :vacancy_id => "SOM/56416")

    stub_request(:get, "http://soap.xbswebservices.info/jobsearch.asmx?WSDL").
      to_return(:status => 200, :body => asset_contents('jobsearch_wsdl'))

    stub_request(:post, "http://soap.xbswebservices.info/jobsearch.asmx").
      with(:body => asset_contents('get_job_detail_request')).
      to_return(:body => asset_contents('get_job_detail_response'))

    details = vacancy.fetch_details_from_api

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

    response = Vacancy.fetch_vacancies_from_api(51.0, 1.0)
    assert_equal 100, response.length
  end

  test '.import_details_from_hash' do
    vacancy_hash = {:currency=>"GBP",
                    :date_received=>"30082011",
                    :distance_sort_order_id=>"2396.97008934328",
                    :es_vacancy=>"Y",
                    :hours=>"35",
                    :hours_display_text=>"37.5 HOURS OVER 5 DAYS",
                    :hours_qualifier=>"per week",
                    :is_national=>false,
                    :is_regional=>false,
                    :location=>{
                        :distance_from_origin=>"2396.97008934328",
                        :latitude=>"50.986008297409",
                        :longitude=>"0.9740371746526",
                        :origin_latitude=>"51",
                        :origin_longitude=>"1",
                        :location_name=>"NEW ROMNEY, KENT"},
                    :location_display_text=>"NEW ROMNEY, KENT",
                    :order_id=>"1",
                    :perm_temp=>"P",
                    :quality=>"86",
                    :received_on=> Time.utc(2011, 8, 30, 0, 0, 0),
                    :soc_code=>"3543",
                    :vacancy_detail=>{
                        :hours=>"0",
                        :soc_code=>"0"},
                    :vacancy_id=>"FOK/12116",
                    :vacancy_title=>"CHARITY FUNDRAISER",
                    :wage=>"See details",
                    :wage_display_text=>"£255 TO £1000 PER WEEK",
                    :wage_qualifier=>"NK",
                    :wage_sort_order_id=>"20"}

    vacancy = Vacancy.new
    vacancy.expects(:vacancy_title=).with(vacancy_hash[:vacancy_title])
    vacancy.expects(:received_on=).with(vacancy_hash[:received_on])
    vacancy.expects(:soc_code=).with(vacancy_hash[:soc_code])
    vacancy.expects(:wage=).with(vacancy_hash[:wage])
    vacancy.expects(:wage_qualifier=).with(vacancy_hash[:wage_qualifier])
    vacancy.expects(:wage_display_text=).with(vacancy_hash[:wage_display_text])
    vacancy.expects(:currency=).with(vacancy_hash[:currency])
    vacancy.expects(:is_national=).with(vacancy_hash[:is_national])
    vacancy.expects(:is_regional=).with(vacancy_hash[:is_regional])
    vacancy.expects(:hours=).with(vacancy_hash[:hours].to_i)
    vacancy.expects(:hours_qualifier=).with(vacancy_hash[:hours_qualifier])
    vacancy.expects(:hours_display_text=).with(vacancy_hash[:hours_display_text])
    vacancy.expects(:location_name=).with(vacancy_hash[:location][:location_name])
    vacancy.expects(:latitude=).with(vacancy_hash[:location][:latitude].to_f)
    vacancy.expects(:longitude=).with(vacancy_hash[:location][:longitude].to_f)
    vacancy.expects(:is_permanent=).with(true)

    vacancy.import_details_from_hash(vacancy_hash)
  end

end
