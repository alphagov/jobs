window.BookmarkedJobsListView = class BookmarkedJobsListView extends Backbone.View

  events:
    'click p.clear-all a': 'clearAll'

  initialize: ->
    @model.bind 'add', => this.render()
    @model.bind 'remove', => this.render()

    $(@el).append('<h2>Jobs List</h2>')

    @list = $('<ul class="bookmarked-jobs-list" />').appendTo(@el)

    $(@el).append('<p class="hint">Save jobs here by clicking "Add to jobs list" on a job.')
    $(@el).append('<p class="clear-copy">Copy about clearing the list on public computers.</p>')
    $(@el).append('<p class="clear-all"><a href="#">Clear List</a></p>')

    $(window).bind 'resize', => this.setHeight()

  setHeight: ->
    # TODO: calculate this relative to the size of the other elements, rather than using a hardcoded value.
    height = $(window).height() - 340;
    $(@list).css(maxHeight: height)

  clearAll: ->
    if confirm("Are you sure you want to remove all the saved jobs in your jobs list?")
      # this is a bit of a hack - we duplicate the array so we're not removing elements from the same array we're iterating over. Damn Javascript.
      _.each(@model.models.slice(0), (job) -> job.destroy())

    return false

  render: ->
    # flush the list and rerender the lot
    @list.empty()

    _.each(@model.models, (job) ->
      bookmarkedJobView = new BookmarkedJobView(model: job)
      @list.append(bookmarkedJobView.render().el)
    , this)

    # hide the clear list button + copy if there's nothing in the list
    if @model.models.length > 0
      $(@el).find('p.clear-all, p.clear-copy').show()
    else
      $(@el).find('p.clear-all, p.clear-copy').hide()

    this.setHeight()

    return this