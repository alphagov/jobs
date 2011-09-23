window.PrintableJobsListView = class PrintableJobsListView extends Backbone.View

  initialize: ->
    @list = $('<ul class="printable-jobs-list" />').appendTo(@el)

  render: ->
    @list.empty()

    _.each(@model.models, (job) ->
      printableJobView = new PrintableJobView(model: job)
      @list.append(printableJobView.render().el)
    , this)

    return this