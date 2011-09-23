window.BookmarkedJobView = class BookmarkedJobView extends Backbone.View

  tagName: "li"
  events:
    'click a.remove-link' : 'clear'

  initialize: ->
    @model.bind 'destroy', => this.removeView()

  render: ->
    $(@el).html($.mustache(@template, @model.attributes))
    return this

  removeView: ->
    $(@el).remove()

  clear: ->
    @model.destroy()
    return false

  template: '''
    <h4><a href="/jobs/{{id}}">{{title}}</a></h4>
    <p class="employer">{{employer}}</p>
    <p class="location">{{location}}</p>
    <p class="remove"><a href="#" class="remove-link">remove</a></p>
  '''