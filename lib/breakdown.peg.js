{
  var plain_text_offset = 0;
  var unidentified_span_next_id = 0;
  var unidentified_spans_stack = [];
  var open_spans = {};
  var result = {
    spans: [],
    plain_text: ""
  };
  var triples_index = {};
}

start = (TripleSection / Body) (Newlines (TripleSection / Body))* {
  // check if there are some spans left open at the end of the code
  if(unidentified_spans_stack.length > 0 || Object.keys(open_spans).length > 0 ) {
    error('Span not closed at end of input.'); // FIXME better error handling: show the line of the first unclosed span
  }

  // resolve triple IDs in spans
  result.spans.forEach(function(span) {
    span.triples = [];
    if(span.id in triples_index) {
      triples_index[span.id].forEach(function(triple) {
        span.triples.push(triple);
      })
    }
  });

  return result;
}

Body 'text body'
  = (Text / Operator)*

TripleSection 'triple section'
  = '+++' (Newlines Triples)? Newlines '+++'

Triples
  = Triple (Newlines Triple)*

Triple
  = s:Subject Spaces p:Predicate Spaces o:Object {
    // add the triple to the index (subject is used as key)
    if(!(s in triples_index)) {
      triples_index[s] = [];
    }
    triples_index[s].push({subject: s, predicate: p, object: o.text, object_type: o.type });
  }

Subject = Id { return text(); }
Predicate = (!(Spaces) .)+ { return text(); }
Object
  = '"' [^"]* '"' { return {type: "literal", text: text()}; }
  / !(Newlines / '"') (!(Newlines) .)* { return {type: 'uri', text: text()}; }

Operator
  = SpanOpen / SpanClose

SpanOpen
  = id:SpanOpenCode {
    if(id === "") {
      // store unidentified spans in stack
      unidentified_spans_stack.push({
        type: 'span',
        start: plain_text_offset,
        start_code_location: location()
      });
    }
    else {
      // store identified spans in an index
      open_spans[id] = {
        type: 'span',
        id: id,
        start: plain_text_offset,
        start_code_location: location()
      };
    }
  }

SpanClose
  = id:SpanCloseCode {
    var span;
    if(id in open_spans) {
      // span found in index: move it to results
      span = open_spans[id];
      delete open_spans[id];
    }
    else {
      if(unidentified_spans_stack.length === 0) {
        error('Trying to close a span without opening it.');
      }
      else {
        // span found in stack: move it to results
        span = unidentified_spans_stack.pop();

        // give unidentified spans an ID (underscore as first character is not allowed by syntax)
        if(id === '') {
          id = '_'+unidentified_span_next_id;
          unidentified_span_next_id += 1;
        }
        span.id = id;
      }
    }

    span.end = plain_text_offset;
    span.end_code_location = location();
    span.text = result.plain_text.slice(span.start, span.end);
    result.spans.push(span);
  }


NoText
  = SpanOpenCode / SpanCloseCode / '\n+++' / '+++\n' / '+++'

SpanOpenCode = '<' id:NullableId '<' { return id; }
SpanCloseCode = '>' id:NullableId '>' { return id; }

Newlines = [ \t\r\n]+
Spaces = [ \t]+

NullableId 'nullable identifier'
  = $(Id / '') { return text(); }

Id 'identifier'
  = [a-zA-Z0-9][_a-zA-Z0-9]* { return text(); }

Text 'text node'
  = (!NoText .)+ {
    result.plain_text += text();
    plain_text_offset += text().length;
  }