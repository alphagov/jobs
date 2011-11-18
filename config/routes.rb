Jobs::Application.routes.draw do
  scope "job-search" do
    root :to => 'home#show', :via => :get
    match 'search', :to => 'search#show', :via => :get
    match 'search', :to => 'search#show_post', :via => :post
    match 'jobs/*id', :to => 'jobs#show', :via => :get, :as => :job
    match 'sitemap.xml',
      :to => 'sitemaps#index',
      :via => :get,
      :as => :sitemap_index

    match 'sitemaps/:date.xml',
      :to => 'sitemaps#show',
      :via => :get,
      :as => :sitemap,
      :date => /\d{4}-\d{2}-\d{2}/

    match 'print', :to => 'home#print', :via => :get
  end
  
  root :to => redirect("/job-search")
end
