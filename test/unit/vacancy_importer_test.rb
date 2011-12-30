# coding:utf-8
require 'test_helper'

DIRECTGOV_JOBS_API_AUTHENTICATION_KEY = 'TESTING'

class VacancyImporterTest < ActiveSupport::TestCase

  test '#fetch_vacancies_from_api' do
    # stub WSDL
    stub_request(:get, "http://soap.xbswebservices.info/jobsearch.asmx?WSDL").
      to_return(:status => 200, :body => asset_contents('jobsearch_wsdl'))

    stub_request(:post, "http://soap.xbswebservices.info/jobsearch.asmx").
      with(:body => asset_contents('all_near_me_request')).
      to_return(:body => asset_contents('all_near_me_response'))

    response = VacancyImporter.fetch_vacancies_from_api(51.0, 1.0)
    assert_equal 100, response.length
  end
end