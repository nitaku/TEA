DocRouter = Backbone.Router.extend
  routes:
    'doc/:doc_id': 'open_document'

  open_document: (id) ->
    id = parseInt(id)

    # FIXME these should be executed in an AppView module
    # destroy the old editor
    d3.select('#editor').selectAll '*'
      .remove()

    # destroy the old graph view
    d3.select('#graph_view').selectAll '*'
      .remove()

    doc = new Document
      id: id

    editor = new Editor
      el: '#editor'
      model: doc

    graph_view = new GraphView
      el: '#graph_view'
      model: doc

    doc.fetch()
