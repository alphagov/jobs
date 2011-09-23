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
        :recency => params[:recency].presence.try(:to_i)
      )
      @results = @search.run

      @formatted_docs = @results.docs.map do |doc|
        Hash.new.tap do |hash|
          hash['id'] = doc['id']
          hash['title'] = doc['title'].try(:titlecase)
          hash['employer'] = doc['employer_name'].try(:titlecase)
          hash['location'] = doc['location_name'].try(:titlecase)
          hash['latitude'] = doc['location_0_coordinate'].to_f
          hash['longitude'] = doc['location_1_coordinate'].to_f
          hash['wage'] = doc['wage_display_text'].try(:titlecase)
          hash['hours'] = doc['hours_display_text'].try(:titlecase)
          hash['description'] = view_context.auto_link(view_context.simple_format(doc['vacancy_description']))
          hash['how_to_apply'] = view_context.auto_link(view_context.simple_format(doc['how_to_apply']))
          hash['eligability_criteria']= view_context.auto_link(view_context.simple_format(doc['eligability_criteria']))
        end
      end
    rescue VacancySearch::SearchError
      render :text => "Error", :status => 500
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