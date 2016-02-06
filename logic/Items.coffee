Items = Backbone.Collection.extend
  model: Item
  sync: (method, model, options) ->
    switch method
      when 'read'
        return d3.json 'http://wafi.iit.cnr.it:33065/ClaviusWeb-1.0.0/ClaviusGraph/list'
          # .header('Content-Type', 'application/json') FIXME server does not accept this
          .post '{}', (error, data) =>
            throw error if error

            @reset data
