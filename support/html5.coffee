
  if String::trim?
    trim = (str) -> String::trim.call str
  else
    trim = (str) -> str.replace(/^\s*/, '').replace(/\s*$/, '')

  # Some classes we'll use to define HTML elements and documents
  class Node
    constructor: (@itemString) ->
    toString: -> "#{@itemString}"
    
  class NodeList extends Array
    constructor: (items...) ->
      @push item for item in items
    toString: ->
      ret = ''
      ret = "#{ret}#{item.toString()}" for item in this
      ret

  class AttributeList
    constructor: (attrs={}) ->
      {data} = attrs
      if data instanceof Object
        {@data} = data
      {noId} = attrs; delete attrs.noId
      
      if not noId
        @id = attrs.id or AttributeList.id();
    
      dataRe = /^data\-/
      eventRe = /^on/
      for own name, attr of attrs
        if dataRe.test name
          @data or= {}
          @data[newName = name.replace dataRe, ''] = attr
        else if eventRe.test(name) and typeof attr == "function"
          AttributeList.eventHandlers[@id] = attr
        else
          if not @[name]
            @[name] = attr
        
    @id: ->
      "__generated_id_#{@id.index++}"
    @id.index = 0

    toString: () ->
      ret = ''
      ret += (if name != "data" || @data !instanceof Object then "#{name}='#{value}' " else '') for own name, value of @
      ret += "data-#{name}='#{value}' " for own name, value of @data || {}
      trim ret
  
    @eventHandlers = {}

  class Element extends Node
    constructor: (config) ->
      {@tag, attributes, @selfClosing, @nodeList} = config
      @attributeList = new Element.AttributeList attributes
      super @toString()
  
    toString: ->
      open = "\n" + trim "<#{@tag} #{@attributeList}>"
      nl = if @nodeList[0] instanceof TextNode then '\n' else ''
      contents = "#{nl}#{@nodeList}\n".replace(/\n/g, "\n  ").replace(/[ ]{2}$/, '')
      close = "</#{@tag}>"
      "#{open}#{contents}#{close}"

    @AttributeList: AttributeList

  class TextNode extends Node
    constructor: (@text='') ->
      super @text
    @empty: new this()

  ###
    Here is our grand Html5 class
    More documentation to come, once the API is a bit more finished
  ###

  class Html5
    constructor: () ->
      isContents = (candidate) ->
        typeof candidate == "string" or typeof candidate == "function" or 
        candidate instanceof Element or candidate instanceof TextNode
      
      for own tag, defaultConfig of @tags
        do (tag, defaultConfig) =>
          # define a function for each tag
          @[tag] = (attrs, contents) ->
            if isContents(attrs) and arguments.length < 2
              [contents, attrs] = [attrs, contents]
            
            attrs or= {}
            (if not attrs[name]? then attrs[name] = defaultVal) for own name, defaultVal of defaultConfig
            
            contents or= TextNode.empty
            if typeof contents == "string"
              contents = new TextNode contents
            
            if contents instanceof TextNode || contents instanceof Element
              contents = new NodeList contents
            else if typeof contents == "function"
              if tag is "script"
                contents = new TextNode "(#{contents})();"
                contents = new NodeList contents
              else
                [defineContents, contents] = [contents, new NodeList()]
                [tmp, @nodeList] = [@nodeList, contents]
                defineContents.call this
                @nodeList = tmp
          
            @nodeList.push new Element {
              tag: tag
              attributes: attrs
              nodeList: contents
            }
  
    # We can generate Html by the functions document and fragment
    document: (definitionFn, config) ->
      @fragment ->
        @DOCTYPE 5
        @html =>
          definitionFn.call @
      , config
    
    fragment: (definitionFn, config) ->
      @nodeList = new NodeList
      definitionFn.call @, config
      ret = @nodeList; delete @nodeList
      ret.toString()
  
    # Some class definitions
    @Element: Element
    @TextNode: TextNode
    @Node: Node
    @NodeList: NodeList
    @AttributeList: AttributeList
    
    # Some pseudo-elements
    text: (txt) ->
      @nodeList.push new TextNode txt
  
    comment: (message) ->
      @nodeList.push new Node "\n\n<!-- #{message} -->"
  
    DOCTYPE: do ->
      doctype = new Node "<!DOCTYPE html>"
      -> @nodeList.push doctype
    
  
    # List html5 tags in alphabetical order, along with any attributes we will
    # use when generating the functions that act as controls for these elements
    tags: {
      a:              {}
      abbr:           {}
      address:        {}
      area:           {}
      article:        {}
      aside:          {}
      audio:          {}
      b:              {}
      base:           {}
      bdo:            {}
      blockquote:     {}
      body:           { noId: true }
      br:             { noId: true }
      button:         {}
      canvas:         {}
      caption:        {}
      cite:           {}
      code:           {}
      col:            {}
      colgroup:       {}
      command:        {}
      datalist:       {}
      dd:             {}
      del:            {}
      details:        {}
      dfn:            {}
      div:            {}
      dl:             {}
      dt:             {}
      em:             {}
      embed:          {}
      fieldset:       {}
      figcaption:     {}
      figure:         {}
      footer:         {}
      form:           {}
      h1:             {}
      h2:             {}
      h3:             {}
      h4:             {}
      h5:             {}
      h6:             {}
      head:           { noId: true }
      header:         {}
      hgroup:         {}
      hr:             { noId: true }
      html:           { noId: true }
      i:              {}
      iframe:         {}
      img:            {}
      input:          {}
      ins:            {}
      keygen:         {}
      kbd:            {}
      label:          {}
      legend:         {}
      li:             {}
      link:           {}
      map:            {}
      mark:           {}
      menu:           {}
      meta:           {}
      meter:          {}
      nav:            {}
      noscript:       {}
      object:         {}
      ol:             {}
      optgroup:       {}
      option:         {}
      output:         {}
      p:              {}
      param:          {}
      pre:            {}
      progress:       {}
      q:              {}
      rp:             {}
      rt:             {}
      ruby:           {}
      s:              {}
      samp:           {}
      script:         {}
      section:        {}
      select:         {}
      small:          {}
      source:         {}
      span:           {}
      strong:         {}
      style:          {}
      sub:            {}
      summary:        {}
      sup:            {}
      table:          {}
      tbody:          {}
      td:             {}
      textarea:       {}
      tfoot:          {}
      th:             {}
      thead:          {}
      time:           {}
      title:          {}
      tr:             {}
      ul:             {}
      var:            {}
      video:          {}
      wbr:            {}
    }
  
  if process?.title is "node"
    module.exports = new Html5()
  else
    @Html5 = new Html5()