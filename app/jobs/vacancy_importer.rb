require 'csv'

class VacancyImporter

  include RetryThis
  extend RetryThis

  def self.bulk_import_from_local_database
    Vacancy.find_in_batches do |vacancies|
      begin
        vacancies.each do |vacancy|
          puts "Inserting solr document: #{vacancy.vacancy_title}"
          vacancy.send_to_solr!
        end
      rescue
        puts "*** Error inserting solr document: #{$!} #{vacancy.inspect}"
      ensure
        $solr.commit!
      end
    end
  end

  def self.bulk_import_from_api(run_date)
    postcodes = CSV.read(File.join(Rails.root, 'data', 'uk.pc.ll.csv'), :headers => true)
    postcodes = postcodes.to_a # we get a Table class back from the CSV library
    postcodes.shift # lose the header

    # we shuffle so we don't keep getting results from a nearby area as we progress through
    postcodes.shuffle.each do |row|
      latitude = row[1].to_f
      longitude = row[2].to_f

      perform(run_date, latitude, longitude)
    end
  end

  def self.perform(run_date, latitude, longitude)
    fetch_vacancies_from_api(latitude, longitude).each do |vacancy_hash|
      vacancy_factory(run_date, vacancy_hash)
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

  def self.fetch_vacancies_from_api(latitude, longitude)
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

  def self.vacancy_factory(run_date, vacancy_hash)
    begin
      vacancy_hash.recursively_symbolize_keys!
      vacancy = Vacancy.find_or_initialize_by_vacancy_id(vacancy_hash[:vacancy_id])
      # if we've already seen this vacancy on this run_date, we can ignore it.
      return if vacancy.most_recent_import_on == run_date

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
end
