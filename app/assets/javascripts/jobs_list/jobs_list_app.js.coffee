window.JobsListApp = class JobsListApp extends Backbone.Model

  initialize: ->
    @bookmarkedJobsCollection = new BookmarkedJobsCollection()

  bootstrap: ->
    # add the paragraph which will contain the add to list link or text
    addToListParagraphElements = $('<p class="add-to-list" />').appendTo('li.job div.job-options')

    # live bind to the add to list links, so the binding updates as they're added and removed
    $('p.add-to-list a').live('click', (event) =>
      @bookmarkedJobsCollection.create($(event.target).parents('li').data())
      return false
    )

    # if anything changes in the jobsList, then refresh the add to list links
    @bookmarkedJobsCollection.bind('all', =>
      $('p.add-to-list').html('<a href="#">Add to list</a>')

      _.each(@bookmarkedJobsCollection.models, (job) ->
        $("li.job[data-id='#{job.id}'] p.add-to-list").html("<span class='disabled'>Already in list</span>")
      )
    )

    # finally, extract what we've already got in localstorage
    @bookmarkedJobsCollection.fetch()

    # now build out the jobs list
    jobsListContainer = $('<div class="job-bookmarks-position" />')
    $('div.search-container').after(jobsListContainer)
    jobsListContent = $('<div class="job-bookmarks" />').appendTo(jobsListContainer)

    jobsListView = new BookmarkedJobsListView(model: @bookmarkedJobsCollection, el: jobsListContent)
    jobsListView.render()