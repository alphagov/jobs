class JobsController < ApplicationController
  include JobFormatter
  
  def show
    @job = VacancySearch.find_individual(params[:id])
    @formatted_job = format_job(@job)
    render :action => 'not_found', :status => :not_found if @job.nil?
  end

end
