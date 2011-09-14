class SearchController < ApplicationController

  helper :search

  def show
    begin
      @search = JobSearch.new(
        :latitude => params[:latitude],
        :longitude => params[:longitude],
        :location => params[:location],
        :query => params[:query],
        :permanent => boolean_or_nil_param(params[:permanent]),
        :full_time => boolean_or_nil_param(params[:full_time])
      )
      @results = @search.run
    rescue JobSearch::SearchError
      render :text => "Error"
    end
  end

end