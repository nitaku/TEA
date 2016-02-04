Editor = Backbone.D3View.extend
  initialize: () ->
    @d3el.classed 'Editor', true

    # define highlighing regexp      
    CodeMirror.defineSimpleMode('mtss', {
      start: [
        {regex: new RegExp('(\\<)([^\\>]*)(\\>)(\\()([^\\)]*)(\\))'), token: ['span_symbol','span_text','span_symbol','entity_symbol','entity_id','entity_symbol']},
        {regex: new RegExp('^___$'), token: 'start_directives', next: 'directives'}
      ],
      directives: [
        {regex: new RegExp('(\\()(.*)(\\))'), token: ['entity_symbol','entity_id','entity_symbol']},
        {regex: new RegExp('.'), token: 'directive'}
      ]
    })

    # create the CodeMirror editor
    editor = CodeMirror @el, {
      mode: 'mtss',
      lineNumbers: false,
      lineWrapping: true,
      gutters: ['error_gutter']
    }

    # 
    editor.on 'change', () -> @model.update editor.getValue()
