class HomeController < ApplicationController

  def show
    expires_in 10.minute, :public => true unless Rails.env.development?
  end

end
