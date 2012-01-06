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

  def self.fetch_all_vacancies_from_api(run_date, latitude, longitude)
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
      found_vacancies = results.body.try(:[], :all_near_me_response).try(:[], :all_near_me_result).try(:[], :vacancies).try(:[], :vacancy_summary) || []

      found_vacancies.each do |vacancy_hash|
        create_vacancy(run_date, vacancy_hash)
      end
    end
  end

  private
  def self.create_vacancy(run_date, vacancy_hash)
    begin
      vacancy_hash.recursively_symbolize_keys!
      vacancy = Vacancy.find_or_initialize_by_vacancy_id(vacancy_hash[:vacancy_id])
      # if we've already seen this vacancy on this run_date, we can ignore it.
      if vacancy.most_recent_import_on == run_date
        Rails.logger.warn "Duplicate job seen"
        return
      end

      if vacancy.new_record?
        vacancy.first_import_on = run_date
        vacancy.most_recent_import_on = run_date
        vacancy.import_details_from_hash(vacancy_hash)

        Rails.logger.info("Importing vacancy: #{vacancy.inspect}")

        # Imports details for a vacancy - if the vacancy is old, it's possible the API might
        # not be able to find it.
        begin
          extra_details = fetch_details_from_api(vacancy)
          if extra_details
            vacancy.employer_name = extra_details[:employer_name]
            vacancy.eligability_criteria = extra_details[:eligability_criteria]
            vacancy.vacancy_description = extra_details[:vacancy_description]
            vacancy.how_to_apply = extra_details[:how_to_apply]
          end
        rescue
          Rails.logger.error("Couldn't fetch extra details")
        end
        vacancy.save!
      else
        vacancy.most_recent_import_on = run_date
        vacancy.save!
      end
    rescue
      Rails.logger.error("An error occurecd processing a vacancy: #{$!} #{vacancy_hash.inspect}")
    end
  end

  def self.soap_client
    @@soap_client ||= Savon::Client.new do
      wsdl.document = "http://soap.xbswebservices.info/jobsearch.asmx?WSDL"
      http.open_timeout = 30
      http.read_timeout = 30
    end
  end

end
