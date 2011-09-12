require 'csv'

class Job < ActiveRecord::Base

  def self.import_all
    postcodes = CSV.read(File.join(Rails.root, 'data', 'uk.pc.ll.csv'), :headers => true)
    postcodes = postcodes.to_a # we get a Table class back from the CSV library
    postcodes.shift # lose the header
    # we shuffle so we don't keep getting results from a nearby area as we progress through
    postcodes.shuffle.each do |row|
      postcode = row[0]
      latitude = row[1].to_f
      longitude = row[2].to_f
      puts "Importing for #{postcode} at #{latitude}, #{longitude}"
      self.import_for_point(latitude, longitude)
    end
  end

  def self.import_for_point(latitude, longitude)
    results = self.fetch_vacancies_from_api(latitude, longitude)
    results.each do |v|
      job = Job.find_or_initialize_by_vacancy_id(v[:vacancy_id])
      job.vacancy_title = v[:vacancy_title]
      job.soc_code = v[:soc_code]

      job.wage = v[:wage]
      job.wage_qualifier = v[:wage_qualifier]
      job.wage_display_text = v[:wage_display_text]
      job.wage_sort_order_id = v[:wage_sort_order_id]

      job.currency = v[:currency] # Do we need this?
      job.is_national = v[:is_national]
      job.is_regional = v[:is_regional]

      job.hours = v[:hours].to_i
      job.hours_qualifier = v[:hours_qualifier]
      job.hours_display_text = v[:hours_display_text]

      job.location_name = v[:location][:location_name]
      job.location_display_name = v[:location_display_name]
      job.latitude = v[:location][:latitude].to_f
      job.longitude = v[:location][:longitude].to_f

      job.is_permanent = v[:perm_temp].downcase == 'p'

      job.first_import_at = Time.now if job.new_record?
      job.most_recent_import_at = Time.now
      job.save!
    end
  end

  private

  def self.fetch_vacancies_from_api(latitude, longitude)
    results = self.soap_client.request "http://ws.dgjobsservice.info/AllNearMe" do
      soap.xml do |xml|
        xml.soap :Envelope, { "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance", "xmlns:xsd" => "http://www.w3.org/2001/XMLSchema", "xmlns:soap" => "http://schemas.xmlsoap.org/soap/envelope/" } do
          xml.soap :Body do
            xml.AllNearMe({ :xmlns => "http://ws.dgjobsservice.info/" }) do
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
                xml.Location do
                  xml.Latitude latitude
                  xml.Longitude longitude
                end
                xml.Radius 100 # TODO: set this to a reasonable value - what unit is this in anyway?
              end
            end
          end
        end
      end
    end

    results.body[:all_near_me_response][:all_near_me_result][:vacancies][:vacancy_summary]
  end

  def self.soap_client
    @@soap_client ||= Savon::Client.new do
      wsdl.document = "http://soap.xbswebservices.info/jobsearch.asmx?WSDL"
      http.open_timeout = 30
    end
  end

end