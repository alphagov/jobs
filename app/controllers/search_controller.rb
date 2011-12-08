class SearchController < ApplicationController
  include JobFormatter

  helper :search

  def show
    begin
      @formerrors = {}
      @search = VacancySearch.new(
          :latitude => params[:latitude],
          :longitude => params[:longitude],
          :location => params[:location],
          :query => params[:query],
          :page => params[:page],
          :permanent => boolean_or_nil_param(params[:permanent]),
          :full_time => boolean_or_nil_param(params[:full_time]),
          :recency => params[:recency].presence.try(:to_i)
      )

      @results = @search.run
    rescue Geogov::UnrecognizedLocationError
      @formerrors[:location] = "We couldn't find your location. Please enter a valid UK postcode"
    rescue VacancySearch::SearchError
      @formerrors[:location] = "Oops! Something went wrong with our search. Please try your search again"
    rescue VacancySearch::LocationMissing
      redirect_to root_path
    end
  end

  # We accept a POST request for search, which redirects to the GET request, but
  # with cleaned up query parameters. This keeps the URL clean.
  def show_post
    @search = VacancySearch.new(
        :latitude => params[:latitude],
        :longitude => params[:longitude],
        :location => params[:location],
        :query => params[:query],
        :page => params[:page],
        :permanent => boolean_or_nil_param(params[:permanent]),
        :full_time => boolean_or_nil_param(params[:full_time]),
        :recency => params[:recency].presence.try(:to_i)
    )
    redirect_to search_path(@search.query_params)
  end

end