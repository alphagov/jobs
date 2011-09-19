require 'csv'

class Job < ActiveRecord::Base

  # for retrying the SOAP requests
  include RetryThis

  validates_presence_of :vacancy_id

  # Traverses the country at random, importing jobs and storing them locally.
  def self.bulk_import
    postcodes = CSV.read(File.join(Rails.root, 'data', 'uk.pc.ll.csv'), :headers => true)
    postcodes = postcodes.to_a # we get a Table class back from the CSV library
    postcodes.shift # lose the header
    # we shuffle so we don't keep getting results from a nearby area as we progress through
    postcodes.shuffle.each do |row|
      postcode = row[0]
      latitude = row[1].to_f
      longitude = row[2].to_f
      self.import_for_point(latitude, longitude)
    end
  end

  # Imports and updates jobs around a specific postcode.
  def self.import_for_point(latitude, longitude)
    results = self.fetch_vacancies_from_api(latitude, longitude)
    results.each do |v|
      job = Job.find_or_initialize_by_vacancy_id(v[:vacancy_id])
      if job.new_record?
        job.vacancy_title = v[:vacancy_title]
        job.soc_code = v[:soc_code]
        job.received_on = v[:received_on]

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
        job.first_import_at = Time.now
        logger.debug "Fetching details for #{job.vacancy_id}"
        job.import_details!
      end
      job.most_recent_import_at = Time.now
      job.save!
    end
  end

  # Imports details for a job - if the job is old, it's possible the API might
  # not be able to find it.
  def import_details!
    details = self.fetch_details_from_api
    if details
      self.employer_name = details[:employer_name]
      self.eligability_criteria = details[:eligability_criteria]
      self.vacancy_description = details[:vacancy_description]
      self.how_to_apply = details[:how_to_apply]
      self.save!
    end
  end

  # Push all jobs to Solr, flushing every batch, and commiting at the end.
  # You probably only want to use this in development.
  def self.send_to_solr
    Job.find_in_batches do |jobs|
      jobs.each do |j|
        j.send_to_solr
      end
      $solr.post_update!
    end
    $solr.commit!
    $solr.optimize!
  end

  # Updates solr without committing
  def send_to_solr
    $solr.update(self.to_solr_document)
  end

  # Updates solr and commits
  def send_to_solr!
    $solr.update!(self.to_solr_document)
  end

  def delete_from_solr
    $solr.delete(self.vacancy_id)
  end

  def to_solr_document
    DelSolr::Document.new.tap do |doc|
      doc.add_field 'id', self.vacancy_id
      doc.add_field 'title', self.vacancy_title, :cdata => true
      doc.add_field 'soc_code', self.soc_code
      doc.add_field 'location', "#{self.latitude},#{self.longitude}"
      doc.add_field 'location_name', self.location_name, :cdata => true
      doc.add_field 'is_permanent', self.is_permanent
      doc.add_field 'hours', self.hours
      doc.add_field 'hours_display_text', self.hours_display_text, :cdata => true
      doc.add_field 'wage_display_text', self.wage_display_text, :cdata => true
      doc.add_field 'received_on', self.received_on.try(:beginning_of_day).try(:iso8601)
      doc.add_field 'vacancy_description', self.vacancy_description, :cdata => true
      doc.add_field 'employer_name', self.employer_name, :cdata => true
      doc.add_field 'how_to_apply', self.how_to_apply, :cdata => true
    end
  end

  def fetch_details_from_api
    retry_this(:times => 3, :error_types => [SocketError, Timeout::Error], :sleep => 1) do |attempt|
      results = self.class.soap_client.request "http://ws.dgjobsservice.info/GetJobDetail" do
        soap.xml do |xml|
          xml.soap :Envelope, { "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance", "xmlns:xsd" => "http://www.w3.org/2001/XMLSchema", "xmlns:soap" => "http://schemas.xmlsoap.org/soap/envelope/" } do
            xml.soap :Body do
              xml.GetJobDetail( { :xmlns => "http://ws.dgjobsservice.info/" }) do
                xml.search do
                  xml.AuthenticationKey DIRECTGOV_JOBS_API_AUTHENTICATION_KEY
                  xml.UniqueIdentifier "1"
                  xml.VacancyID self.vacancy_id
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

  def self.soap_client
    @@soap_client ||= Savon::Client.new do
      wsdl.document = "http://soap.xbswebservices.info/jobsearch.asmx?WSDL"
      http.open_timeout = 30
    end
  end

end
