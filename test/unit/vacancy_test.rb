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
    document.add_field 'received_on', Date.today.beginning_of_day.iso8601
    document.add_field 'vacancy_description', "Work for us", :cdata => true
    document.add_field 'employer_name', "Alphagov", :cdata => true
    document.add_field 'how_to_apply', 'Send us an email', :cdata => true

    assert_equal vacancy.to_solr_document.xml, document.xml
  end

  test '.send_to_solr' do
    vacancy = Factory.build(:vacancy)
    vacancy.stubs(:to_solr_document).returns(mock())
    $solr.expects(:update!).with(vacancy.to_solr_document).returns(true)
    assert_equal true, vacancy.send_to_solr
  end

  test '.send_to_solr!' do
    vacancy = Factory.build(:vacancy)
    vacancy.stubs(:to_solr_document).returns(mock())
    $solr.expects(:update_and_commit!).with(vacancy.to_solr_document).returns(true)
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

end