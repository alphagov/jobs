class JobsController < ApplicationController

  def show
    @job = VacancySearch.find_individual(params[:id])
    render :action => 'not_found', :status => :not_found if @job.nil?
  end

end
