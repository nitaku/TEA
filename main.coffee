app = {}

d3.text 'lib/breakdown.peg.js', (error, breakdown_grammar) ->
  app.breakdown_grammar = breakdown_grammar

  # client-side URI management
  doc_router = new DocRouter
    app: app

  Backbone.history.start() # FIXME enable HistoryAPI
