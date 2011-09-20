class JobsController < ApplicationController

  def show
    @job = VacancySearch.find_individual(params[:id])
  end

end
