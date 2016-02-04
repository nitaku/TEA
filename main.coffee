doc = new Document()

# stub of Editor view
doc.on 'parse_error', () ->
  console.log 'parse error'

graph_view = new GraphView
  el: '#graph_view'
  model: doc

editor = new Editor
  el: '#editor'
  model: doc
