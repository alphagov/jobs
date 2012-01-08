# coding:utf-8
require 'test_helper'

DIRECTGOV_JOBS_API_AUTHENTICATION_KEY='TESTING'

class VacancyApiClientTest < ActiveSupport::TestCase

  test 'fetch_all_vacancies_from_api' do
    stub_request(:get, "http://soap.xbswebservices.info/jobsearch.asmx?WSDL").
        to_return(:status => 200, :body => asset_contents('jobsearch_wsdl'))

    stub_request(:post, "http://soap.xbswebservices.info/jobsearch.asmx").
        with(:body => asset_contents('all_near_me_request')).
        to_return(:body => asset_contents('all_near_me_response'))

    response = VacancyApiClient.fetch_all_vacancies_from_api(51.0, 1.0)
    assert_equal 100, response.length
  end

  test 'fetch_details_from_api' do
    vacancy = Factory.create(:vacancy, :vacancy_id => "SOM/56416")

    stub_request(:get, "http://soap.xbswebservices.info/jobsearch.asmx?WSDL").
        to_return(:status => 200, :body => asset_contents('jobsearch_wsdl'))

    stub_request(:post, "http://soap.xbswebservices.info/jobsearch.asmx").
        with(:body => asset_contents('get_job_detail_request')).
        to_return(:body => asset_contents('get_job_detail_response'))

    details = VacancyApiClient.fetch_details_from_api(vacancy)

    # just to prove we're getting the hash back
    assert_equal details[:age_exempt], "N"
  end
end