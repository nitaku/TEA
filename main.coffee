doc = new Document()

# stub of Editor view
doc.on 'parse_error', () ->
  console.log 'parse error'

# stub of Graph view
doc.on 'change:graph', () ->
  console.log 'graph changed'

# example of correct update
doc.update '''hu<u>(1)u
___
(1) a a'''

# example of bad update
doc.update 'dfdf<<<<'

editor = new Editor
  el: '#editor'
  model: doc