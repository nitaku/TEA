doclist = new Items()

sel = new ItemSelection()

app = {}

d3.text 'lib/breakdown.peg.js', (error, breakdown_grammar) ->
  app.breakdown_grammar = breakdown_grammar

  # client-side URI management
  doc_router = new DocRouter
    selection: sel
    app: app

  Backbone.history.start() # FIXME enable HistoryAPI


  navigator = new Navigator
    el: '#navigator'
    selection: sel
    items: doclist
    doc_router: doc_router

  doclist.fetch()

  d3.select(document).on 'keyup', () ->
    if d3.event.altKey and d3.event.ctrlKey and d3.event.code is 'KeyN'
      navigator.d3el.classed 'hidden', not navigator.d3el.classed 'hidden'
