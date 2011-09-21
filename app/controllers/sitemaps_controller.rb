class SitemapsController < ApplicationController

  layout nil

  def index
    @received_on_counts = VacancySearch.received_on_counts
    expires_in 1.day, :public => true
  end

  def show
    @date = Date.parse(params[:date])
    @vacancy_ids = VacancySearch.ids_for_date(@date)
    expires_in 1.day, :public => true
  end

end