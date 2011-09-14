Jobs::Application.routes.draw do
  root :to => 'home#show', :via => :get
  match 'search', :to => 'search#show', :via => :get
  match 'jobs/*id', :to => 'jobs#show', :via => :get, :as => :job
end
