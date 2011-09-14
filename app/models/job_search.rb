class JobSearch

  class InvalidLocationCombination < RuntimeError; end
  class LocationMissing < RuntimeError; end
  class SearchError < RuntimeError; end

  attr_accessor :location, :latitude, :longitude
  attr_accessor :query, :permanent, :full_time
  attr_accessor :page, :per_page

  DEFAULT_QUERY = "*:*"
  DEFAULT_PER_PAGE = 50

  def initialize(options)
    @location = options.delete(:location)
    @latitude = options.delete(:latitude).try(:to_f)
    @longitude = options.delete(:longitude).try(:to_f)

    raise InvalidLocationCombination if @location.present? && (@latitude.present? || @longitude.present?)
    raise LocationMissing if @location.blank? && (@latitude.blank? || @longitude.blank?)

    @permanent = options.delete(:permanent)
    @full_time = options.delete(:full_time)
    @per_page = options.delete(:per_page).presence || DEFAULT_PER_PAGE
    @query = options.delete(:query).presence || DEFAULT_QUERY
    @page = options.delete(:page).presence || 1
  end

  def run
    geocode if @location.present?

    params = {
      :query => @query,
      :fields => "*",
      :sort => "geodist() asc",
      :sfield => "location",
      :pt => "#{@latitude},#{@longitude}",
      :limit => @per_page,
      :offset => (@page-1)*@per_page,
      :filters => []
    }

    params[:filters] << { :is_permanent => @permanent } unless @permanent.nil?
    params[:filters] << (@full_time ? "hours:[30 TO *]" : "hours:[* TO 29]") unless @full_time.nil?

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
      hash[:query] = query unless (query.nil? || query == DEFAULT_QUERY)
      hash[:page] = page unless (page.nil? || page == 1)
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

  private

  def geocode
    point = Geogov.lat_lon_from_postcode(@location)
    @latitude = point['lat']
    @longitude = point['lon']
  end

end