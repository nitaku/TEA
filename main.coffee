doclist = new Items()
doclist.add new Item
  id: 1
  name: 'pippo'
doclist.add new Item
  id: 2
  name: 'topolino'

sel = new ItemSelection()

navigator = new Navigator
  el: '#navigator'
  selection: sel
  items: doclist

sel.on 'change', () ->
  # destroy the old editor
  d3.select('#editor').selectAll '*'
    .remove()

  # destroy the old graph view
  d3.select('#graph_view').selectAll '*'
    .remove()

  doc = new Document()

  # stub of Editor view
  doc.on 'parse_error', () ->
    console.log 'parse error'

  editor = new Editor
    el: '#editor'
    model: doc

  graph_view = new GraphView
    el: '#graph_view'
    model: doc
