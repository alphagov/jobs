class VacancyApiClient

  include RetryThis
  extend RetryThis

  def self.fetch_details_from_api(vacancy)
    retry_this(:times => 3, :error_types => [SocketError, Timeout::Error], :sleep => 1) do |attempt|
      results = soap_client.request "http://ws.dgjobsservice.info/GetJobDetail" do
        soap.xml do |xml|
          xml.soap :Envelope, {"xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance", "xmlns:xsd" => "http://www.w3.org/2001/XMLSchema", "xmlns:soap" => "http://schemas.xmlsoap.org/soap/envelope/"} do
            xml.soap :Body do
              xml.GetJobDetail({:xmlns => "http://ws.dgjobsservice.info/"}) do
                xml.search do
                  xml.AuthenticationKey DIRECTGOV_JOBS_API_AUTHENTICATION_KEY
                  xml.UniqueIdentifier "1"
                  xml.VacancyID vacancy.vacancy_id
                end
              end
            end
          end
        end
      end
      results.body.try(:[], :get_job_detail_response).try(:[], :get_job_detail_result).try(:[], :vacancy)
    end
  end

  def self.fetch_all_vacancies_from_api(latitude, longitude)
    retry_this(:times => 3, :error_types => [SocketError, Timeout::Error], :sleep => 1) do |attempt|
      results = soap_client.request "http://ws.dgjobsservice.info/AllNearMe" do
        soap.xml do |xml|
          xml.soap :Envelope, {"xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance", "xmlns:xsd" => "http://www.w3.org/2001/XMLSchema", "xmlns:soap" => "http://schemas.xmlsoap.org/soap/envelope/"} do
            xml.soap :Body do
              xml.AllNearMe({:xmlns => "http://ws.dgjobsservice.info/"}) do
                xml.search do
                  xml.AuthenticationKey DIRECTGOV_JOBS_API_AUTHENTICATION_KEY
                  xml.UniqueIdentifier "1"
                  xml.MaximumNumberOfResults 100 # 100 is the maximum allowed
                  xml.IncludeNationalVacancies true
                  xml.IncludeRegionalVacancies true
                  xml.Temporary true
                  xml.Permanent true
                  xml.PartTime true
                  xml.FullTime true
                  xml.MaxAge 28
                  xml.Location do
                    xml.Latitude latitude
                    xml.Longitude longitude
                  end
                  xml.Radius 50 # TODO: set this to a reasonable value - what unit is this in anyway?
                end
              end
            end
          end
        end
      end
      results.body.try(:[], :all_near_me_response).try(:[], :all_near_me_result).try(:[], :vacancies).try(:[], :vacancy_summary) || []
    end
  end

  private
  def self.soap_client
    @@soap_client ||= Savon::Client.new do
      wsdl.document = "http://soap.xbswebservices.info/jobsearch.asmx?WSDL"
      http.open_timeout = 30
      http.read_timeout = 30
    end
  end
end
