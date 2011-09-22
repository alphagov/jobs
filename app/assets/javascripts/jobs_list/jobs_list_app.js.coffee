window.JobsListApp = class JobsListApp extends Backbone.Model

  initialize: ->
    window.jobsList = new JobsList()
    window.jobsList.fetch()

    $('li.job a.add-to-list').click(->
      jobsList.create($(this).parents('li').data())
      return false
    )

  bootstrap: ->
    jobsListContainer = $('<div class="job-bookmarks-position"><div class="job-bookmarks-wrapper" /></div>')
    $('div.search-container').after(jobsListContainer)
    jobsListContent = $('<div class="job-bookmarks" />').appendTo(jobsListContainer)

    jobsListView = new JobsListView(model: jobsList, el: jobsListContent)
    jobsListView.render()