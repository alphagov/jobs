window.PrintableJobsListApp = class PrintableJobsListApp extends Backbone.Model

  initialize: ->
    @bookmarkedJobsCollection = new BookmarkedJobsCollection()

  bootstrap: ->
    @bookmarkedJobsCollection.fetch()

    jobsListElement = $('div.jobs-list')
    jobsListElement.empty()

    printableJobsListView = new PrintableJobsListView(
      model: @bookmarkedJobsCollection
      el: jobsListElement
    ).render()

    window.print()