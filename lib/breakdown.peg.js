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


  var predicate_aliases = {
    is: 'its:taIdentRef',
    type: 'its:taClassRef',
    page: 'foaf:page',
    comment: 'rdfs:comment'
  };

  function resolve_alias(d) {
    return d in predicate_aliases ? predicate_aliases[d] : d;
  }

  var prefixes = {
    rdf: 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
    owl: 'http://www.w3.org/2002/07/owl#',
    rdfs: 'http://www.w3.org/2000/01/rdf-schema#',
    foaf: 'http://xmlns.com/foaf/0.1/',
    dbo: 'http://dbpedia.org/ontology/',
    dbr: 'http://dbpedia.org/resource/',
    wiki: 'http://en.wikipedia.org/wiki/',
    cll: 'http://claviusontheweb.it/lexicon/',
    lvont: 'http://lexvo.org/ontology#',
    lexvo: 'http://lexvo.org/id/',
    its: 'http://www.w3.org/2005/11/its/rdf#',
    wd: 'http://www.wikidata.org/entity/'
  }

  // FIXME handle unknown predicates
  function urify(d) {
    var splitted = (''+d).split(':');
    if(splitted.length != 2 || splitted[0] == 'http')
      return d;
    else
      return prefixes[splitted[0]] + splitted[1];
  }
}

start = Section (Newlines Section)* {
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

    span.triples.forEach(function(triple) {
      // resolve predicate aliases
      triple.predicate_prefixed = resolve_alias(triple.predicate);

      // resolve prefixes into URIs
      triple.predicate_uri = urify(triple.predicate_prefixed);
      triple.object_uri = triple.object_type == 'literal' ? triple.object : urify(triple.object);
    });
  });

  return result;
}

Section 'code section'
  = TripleSection / CommentSection / Break / Body

CommentSection 'comment section'
  = '/*' [^(\*/)]* '*/' {
    return ''; // skip comments
  }

Break 'break section'
  = '---' Spaces Id {
    // TODO save as annotation
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
  = '"' lc:LiteralContent '"' { return {type: "literal", text: lc}; }
  / !(Newlines / '"') (!(Newlines) .)* { return {type: 'uri', text: text()}; }

LiteralContent
  = [^"]* { return text(); }

Operator
  = SpanOpen / SpanClose / AAOpen / AAClose / Gap / EAOpen / EAClose

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

AAOpen 'Author\'s addition open'
  =  AAOpenCode

AAClose 'Author\'s addition close'
  =  AACloseCode

AAOpenCode
  = '{' { return ''; }

AACloseCode
  = '}' { return ''; }

EAOpen 'Editor\'s addition open'
  =  EAOpenCode

EAClose 'Editor\'s addition close'
  =  EACloseCode

EAOpenCode
  = '[' { return ''; }

EACloseCode
  = ']' { return ''; }

Gap 'Gap'
  = GapCode

GapCode
  = '[...]' / '[…]' { return ''; }


NoText
  = SpanOpenCode / SpanCloseCode / AAOpenCode / AACloseCode / GapCode / EAOpenCode / EACloseCode / '\n+++' / '\n/*' / '\n---'

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
