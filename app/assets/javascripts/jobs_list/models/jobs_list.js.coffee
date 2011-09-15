window.JobsList = class JobsList extends Backbone.Collection
  model: Job
  localStorage: new Store("jobs")