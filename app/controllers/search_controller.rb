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
        :full_time => boolean_or_nil_param(params[:full_time])
      )
      @results = @search.run
    rescue VacancySearch::SearchError
      render :text => "Error"
    end
  end

end