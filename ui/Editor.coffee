Editor = Backbone.D3View.extend
  initialize: () ->
    @d3el.classed 'Editor', true

    # define highlighting regexp
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
    # Chrome bug workaround (https://github.com/codemirror/CodeMirror/issues/3679)
    @d3el
      .style
        position: 'relative'
    wrapper = @d3el.append 'div'
      .style
        position: 'absolute'
        height: '100%'
        width: '100%'

    editor = CodeMirror wrapper.node(), {
      mode: 'mtss',
      lineNumbers: false,
      lineWrapping: true,
      gutters: ['error_gutter']
    }

    @textmarks = []
    @listenTo @model, 'annotation', () ->
      for textmark in @textmarks
        textmark.clear()
        
      for annotation in @model.annotations
        console.log annotation
        
        textmark = editor.markText {line: annotation.code_line, ch: annotation.code_start}, {line: annotation.code_line, ch: annotation.code_end}, {className: 'annotation'}
        @textmarks.push textmark

    editor.on 'change', () =>
      @model.update editor.getValue()
