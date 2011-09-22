class VacancySearch

  class InvalidLocationCombination < RuntimeError; end
  class LocationMissing < RuntimeError; end
  class SearchError < RuntimeError; end

  attr_accessor :location, :latitude, :longitude, :distance
  attr_accessor :query, :permanent, :full_time, :recency
  attr_accessor :page, :per_page

  DEFAULT_QUERY = "*:*"
  DEFAULT_PER_PAGE = 50
  DEFAULT_DISTANCE = 50
  MILES_TO_KM_MULTIPLIER = 1.609344

  def initialize(options)
    @location = options.delete(:location)
    @latitude = options.delete(:latitude).try(:to_f)
    @longitude = options.delete(:longitude).try(:to_f)

    raise InvalidLocationCombination if @location.present? && (@latitude.present? || @longitude.present?)
    raise LocationMissing if @location.blank? && (@latitude.blank? || @longitude.blank?)

    @permanent = options.delete(:permanent)
    @full_time = options.delete(:full_time)
    @per_page = options.delete(:per_page).presence || DEFAULT_PER_PAGE
    @query = options.delete(:query).presence
    @page = options.delete(:page).try(:to_i) || 1
    @distance = options.delete(:distance) || DEFAULT_DISTANCE
    @recency = options.delete(:recency).try(:to_i)
  end

  def run
    geocode if @location.present?

    params = {
      :query => @query.present? ? "title:#{@query}" : "*:*",
      :fields => "*",
      :fq => "{!bbox}",
      :sort => "geodist() asc",
      :sfield => "location",
      :pt => "#{@latitude},#{@longitude}",
      :d => @distance * MILES_TO_KM_MULTIPLIER,
      :limit => @per_page,
      :offset => (@page-1)*@per_page,
      :filters => []
    }

    params[:filters] << { :is_permanent => @permanent } unless @permanent.nil?
    params[:filters] << (@full_time ? "hours:[30 TO *]" : "hours:[* TO 29]") unless @full_time.nil?
    # round to beginning of day and subtract x days
    params[:filters] << "received_on:[NOW/DAY-#{@recency}DAY TO *]" unless @recency.nil?

    $solr.query('standard', params) || raise(SearchError)
  end

  def query_params
    Hash.new.tap do |hash|
      if location.present?
        hash[:location] = location
      else
        hash[:latitude] = latitude
        hash[:longitude] = longitude
      end

      hash[:permanent] = permanent unless permanent.nil?
      hash[:full_time] = full_time unless full_time.nil?
      hash[:recency] = recency unless recency.nil?
      hash[:query] = query unless (query.nil? || query == DEFAULT_QUERY)
    end
  end

  def self.find_individual(job_id)
    params = {
      :query => "*:*",
      :fields => "*",
      :filters => ["id:#{job_id}"],
      :limit => 1
    }

    results = $solr.query('standard', params) || raise(SearchError)
    results.docs.first
  end

  def self.received_on_counts
    params = {
      :query => "*:*",
      :limit => 0,
      :facets => [{ :field => 'received_on', :mincount => 10 }]
    }

    results = $solr.query('standard', params) || raise(SearchError)
    Hash.new.tap do |hash|
      results.facet_field_values('received_on').each do |v|
        date = Time.iso8601(v).to_date
        count = results.facet_field_count('received_on', v)
        hash[date] = count
      end
    end.sort_by { |k, v| k }
  end

  def self.ids_for_date(date)
    params = {
      :query => "*:*",
      :limit => 50000,
      :sort => "id asc",
      :fields => "id",
      :filters => ["received_on:[#{date.beginning_of_day.iso8601} TO #{date.end_of_day.iso8601}]"]
    }

    results = $solr.query('standard', params) || raise(SearchError)
    results.docs.map { |d| d['id'] }
  end

  private

  def geocode
    point = Geogov.lat_lon_from_postcode(@location)
    @latitude = point['lat']
    @longitude = point['lon']
  end

end