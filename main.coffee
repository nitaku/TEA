doclist = new Items()

sel = new ItemSelection()

navigator = new Navigator
  el: '#navigator'
  selection: sel
  items: doclist

doclist.fetch()

sel.on 'change', () ->
  # destroy the old editor
  d3.select('#editor').selectAll '*'
    .remove()

  # destroy the old graph view
  d3.select('#graph_view').selectAll '*'
    .remove()

  doc = new Document
    id: sel.attributes.id

  editor = new Editor
    el: '#editor'
    model: doc

  graph_view = new GraphView
    el: '#graph_view'
    model: doc

  doc.fetch()

d3.select(document).on 'keyup', () ->
  if d3.event.altKey and d3.event.ctrlKey and d3.event.code is 'KeyN'
    navigator.d3el.classed 'hidden', not navigator.d3el.classed 'hidden'
