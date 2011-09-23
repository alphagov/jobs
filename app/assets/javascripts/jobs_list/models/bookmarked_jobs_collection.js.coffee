window.BookmarkedJobsCollection = class BookmarkedJobsCollection extends Backbone.Collection
  model: BookmarkedJob
  localStorage: new Store("jobs")