DocRouter = Backbone.Router.extend
  routes:
    'docs/:id': 'open_document'

  initialize: (conf) ->
    @app = conf.app

  open_document: (id) ->
    # FIXME these should be executed in an AppView module
    # destroy the old editor
    d3.select('#editor').selectAll '*'
      .remove()

    # destroy the old annotation view
    d3.select('#annotation_view').selectAll '*'
      .remove()

    # destroy the old graph view
    d3.select('#image_view').selectAll '*'
      .remove()

    doc = new Document
      id: id

    image_view = new ImageView
      el: '#image_view'
      model: doc

    editor = new Editor
      el: '#editor'
      breakdown_grammar: @app.breakdown_grammar
      model: doc

    annotation_view = new AnnotationView
      el: '#annotation_view'
      model: doc

    doc.fetch()