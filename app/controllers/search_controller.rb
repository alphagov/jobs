class SearchController < ApplicationController

  helper :search

  def show
    begin
      @search = VacancySearch.new(
        :latitude => params[:latitude],
        :longitude => params[:longitude],
        :location => params[:location],
        :query => params[:query],
        :page => params[:page],
        :permanent => boolean_or_nil_param(params[:permanent]),
        :full_time => boolean_or_nil_param(params[:full_time]),
        :recency => params[:recency]
      )
      @results = @search.run
    rescue VacancySearch::SearchError
      render :text => "Error", :status => 500
    rescue VacancySearch::LocationMissing
      redirect_to root_path
    end
  end

end