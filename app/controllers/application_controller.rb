class ApplicationController < ActionController::Base
  helper_method :boolean_or_nil_param

  def boolean_or_nil_param(param)
    if param.present?
      return (param == '1' || param == 'true')
    else
      return nil
    end
  end

end
