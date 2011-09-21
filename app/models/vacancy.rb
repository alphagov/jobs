require 'csv'

class Vacancy < ActiveRecord::Base

  class ExtraDetailsNotFound < RuntimeError; end

  # for retrying the SOAP requests
  include RetryThis
  extend RetryThis

  validates_presence_of :vacancy_id

  def self.async_bulk_import(run_date)
    postcodes = CSV.read(File.join(Rails.root, 'data', 'uk.pc.ll.csv'), :headers => true)
    postcodes = postcodes.to_a # we get a Table class back from the CSV library
    postcodes.shift # lose the header
    # we shuffle so we don't keep getting results from a nearby area as we progress through
    postcodes.shuffle.each do |row|
      postcode = row[0]
      latitude = row[1].to_f
      longitude = row[2].to_f
      Resque.enqueue(PointImporterJob, run_date, latitude, longitude)
    end
  end

  def import_details_from_hash(v)
    self.vacancy_title = v[:vacancy_title]
    self.soc_code = v[:soc_code]
    self.received_on = v[:received_on]

    self.wage = v[:wage]
    self.wage_qualifier = v[:wage_qualifier]
    self.wage_display_text = v[:wage_display_text]
    self.wage_sort_order_id = v[:wage_sort_order_id]

    self.currency = v[:currency] # Do we need this?
    self.is_national = v[:is_national]
    self.is_regional = v[:is_regional]

    self.hours = v[:hours].to_i
    self.hours_qualifier = v[:hours_qualifier]
    self.hours_display_text = v[:hours_display_text]

    self.location_name = v[:location][:location_name]
    self.location_display_name = v[:location_display_name]
    self.latitude = v[:location][:latitude].to_f
    self.longitude = v[:location][:longitude].to_f

    self.is_permanent = v[:perm_temp].downcase == 'p'
  end

  # Imports details for a vacancy - if the vacancy is old, it's possible the API might
  # not be able to find it.
  def import_extra_details
    details = self.fetch_details_from_api
    if details
      self.employer_name = details[:employer_name]
      self.eligability_criteria = details[:eligability_criteria]
      self.vacancy_description = details[:vacancy_description]
      self.how_to_apply = details[:how_to_apply]
    else
      raise ExtraDetailsNotFound
    end
  end

  def import_extra_details!
    import_extra_details || raise(ExtraDetailsNotFound)
  end

  # Push all vacancies to Solr, flushing every batch, and commiting at the end.
  # You probably only want to use this in development.
  def self.send_to_solr
    Vacancy.find_in_batches do |vacancies|
      vacancies.each do |j|
        j.send_to_solr
      end
      $solr.post_update!
    end
    $solr.commit!
    $solr.optimize!
  end

  # Updates solr without committing
  def send_to_solr
    $solr.update!(self.to_solr_document)
  end

  # Updates solr and commits
  def send_to_solr!
    $solr.update_and_commit!(self.to_solr_document)
  end

  def delete_from_solr
    $solr.delete(self.vacancy_id)
  end

  def self.purge_expired
    Vacancy.where(['most_recent_import_on < ?', Date.yesterday]).find_each do |vacancy|
      vacancy.delete_from_solr && vacancy.destroy
    end
    $solr.commit!
    $solr.optimize!
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
      http.read_timeout = 30
    end
  end

end
