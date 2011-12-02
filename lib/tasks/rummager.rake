namespace :rummager do
  desc "Reindex search engine"
  task :index => :environment do
    documents = [{
      "title" => "Job search",
      "description" => "Find job openings",
      "format" => "jobs",
      "link" => "/job-search",
      "indexable_content" => "search filter save job print employment",
    }]
    Rummageable.index documents
  end
end
