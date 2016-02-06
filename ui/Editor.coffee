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

    # Chrome bug workaround (https://github.com/codemirror/CodeMirror/issues/3679)
    @d3el
      .style
        position: 'relative'
    wrapper = @d3el.append 'div'
      .style
        position: 'absolute'
        height: '100%'
        width: '100%'

    # create the CodeMirror editor
    editor = CodeMirror wrapper.node(), {
      mode: 'mtss',
      lineNumbers: false,
      gutters: ['error_gutter']
    }

    editor.on 'change', () =>
      @model.update editor.getValue()

    # annotation highlighting
    @annotation_textmarks = []

    @listenTo @model, 'annotation', () ->
      for textmark in @annotation_textmarks
        textmark.clear()

      for annotation in @model.annotations
        newline_matches = if annotation.content.match(/\n/g) then annotation.content.match(/\n/g).length else 0

        #@annotation_textmarks.push editor.markText {line: annotation.code_line, ch: annotation.code_start}, {line: annotation.code_line+newline_matches, ch: annotation.code_end}, {className: 'annotation'}

        @annotation_textmarks.push editor.markText {line: annotation.code_line, ch: annotation.code_start}, {line: annotation.code_line, ch: annotation.code_start+1}, {className: 'square_bracket'}
        @annotation_textmarks.push editor.markText {line: annotation.code_line, ch: annotation.code_start+annotation.content.length+1}, {line: annotation.code_line, ch: annotation.code_start+annotation.content.length+2}, {className: 'square_bracket'}

        @annotation_textmarks.push editor.markText {line: annotation.code_line, ch: annotation.code_start}, {line: annotation.code_line, ch: annotation.code_start+annotation.content.length+2}, {className: 'annotation'}

        if annotation.type is 'annotation'
          @annotation_textmarks.push editor.markText {line: annotation.code_line, ch: annotation.code_end-1}, {line: annotation.code_line, ch: annotation.code_end}, {className: 'round_bracket'}
          @annotation_textmarks.push editor.markText {line: annotation.code_line, ch: annotation.code_end-annotation.id.length-2}, {line: annotation.code_line, ch: annotation.code_end}, {className: 'round_bracket'}
