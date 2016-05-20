Document = Backbone.Model.extend
  defaults:
    label: null
    code: null
    text: null
    annotations: null
    images: null
  urlRoot: 'http://wafi.iit.cnr.it/webvis/annotarium/api/docs'
