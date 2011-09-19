window.JobsListApp = class JobsListApp extends Backbone.Model

  initialize: ->
    window.jobsList = new JobsList()
    window.jobsList.fetch()

    $('tr.job a.add-to-jobs-list').click(->
      jobsList.create($(this).parents('tr').data())
      return false
    )


  bootstrap: ->
    jobsListContainer = $('<div class="jobs-list-container" />').appendTo('div#search')
    jobsListContent = $('<div class="jobs-list-content" />').appendTo(jobsListContainer)

    jobsListView = new JobsListView(model: jobsList, el: jobsListContent)
    jobsListView.render()