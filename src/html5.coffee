
  if String::trim?
    trim = (str) -> String::trim.call str
  else
    trim = (str) -> str.replace(/^\s*/, '').replace(/\s*$/, '')
    
  hasProp = Object::hasOwnProperty

  # Some classes we'll use to define HTML elements and documents
  class Node
    constructor: (@itemString) ->
    toString: -> trim "#{@itemString}"
    
  class NodeList extends Array
    constructor: (items...) ->
      @push item for item in items
    toString: ->
      ret = ''
      ret = "#{ret}#{trim item.toString()}" for item in this
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
      "_#{@id.index++}_"
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
      
      {@noClose} = attributes; delete attributes.noClose
      @noClose or= false
      
      @attributeList = new Element.AttributeList attributes
      super @toString()
  
    toString: ->
      open = "\n" + trim "<#{@tag} #{@attributeList}>"
      contents = "#{@nodeList}\n".replace(/\n/g, "\n  ").replace(/[ ]{2}$/, '')
      close = "</#{@tag}>"
      if @noClose
        open
      else
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
        typeof candidate != "object" or candidate instanceof Element or
        candidate instanceof TextNode
      
      for own tag, defaultConfig of @tags
        do (tag, defaultConfig) =>
          # define a function for most tags
          # If it's already in the prototype, then don't redefine it
          unless hasProp.call this.constructor.prototype, tag
            @[tag] = (attrs, contents) ->
              if isContents(attrs) and arguments.length < 2
                [contents, attrs] = [attrs, contents]
              
              attrs or= {}
              (if not attrs[name]? then attrs[name] = defaultVal) for own name, defaultVal of defaultConfig
            
              contents or= TextNode.empty
              if typeof contents == "string"
                contents = new TextNode contents
            
              if tag is "script"
                if contents.text or typeof contents == "function"
                  contents = new TextNode "(#{contents})();"
                else
                  contents = TextNode.empty
              
              if contents instanceof TextNode || contents instanceof Element
                contents = new NodeList contents
              else if typeof contents == "function"
                [defineContents, contents] = [contents, new NodeList()]
                [tmp, @nodeList] = [@nodeList, contents]
                defineContents.call @currentScope
                @nodeList = tmp
          
              @nodeList.push new Element {
                tag: tag
                attributes: attrs
                nodeList: contents
              }
  
    # We can generate Html by the functions document and fragment
    document: (definitionFn, config={}) ->
      config.templateContext or= this
      @currentScope or= config
      @fragment ->
        @doctype 5
        @html =>
          definitionFn.call config
      , config
    
    fragment: (definitionFn, config={}) ->
      config.templateContext or= this
      @currentScope = config
      
      returnNodeList = config.returnNodeList or false
      delete config.returnNodeList
      nodeList = config.nodeList
      delete config.nodeList
      
      [tmp, @nodeList] = [@nodeList, nodeList or new NodeList()]
      definitionFn.call @currentScope
      [ret, @nodeList] = [@nodeList, tmp]
      
      delete @currentScope
      
      if config.returnNodeList
        ret
      else
        ret?.toString() or ''
  
    # Some class definitions
    @Element: Element
    @TextNode: TextNode
    @Node: Node
    @NodeList: NodeList
    @AttributeList: AttributeList
    
    # Define exceptions to the normal tag rendering process
    br: (repeat=1) ->
      @nodeList.push "<br>" for [1..repeat]
        
    # Some pseudo-elements
    text: (txt) ->
      @nodeList.push new TextNode txt
    space: (repeat=1) ->
      (@text "&nbsp;") for [1..repeat]
    comment: (message) ->
      @nodeList.push new Node "\n\n<!-- #{message} -->"
    DOCTYPE: do ->
      doctype = new Node "<!DOCTYPE html>"
      -> @nodeList.push doctype
    doctype: -> @DOCTYPE arguments...
    clear: (clr="both") -> @div style:"clear:#{clr};"
    expose: (object, namespace) ->
      namespace = "window.#{namespace}"
      @script "function () { #{namespace} = #{JSON.stringify object}; }"
    
    
  
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
      br:             { noId: true, noClose: true }
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
      hr:             { noId: true, noClose: true }
      html:           { noId: true }
      i:              {}
      iframe:         {}
      img:            { noClose: true }
      input:          { noClose: true }
      ins:            {}
      keygen:         {}
      kbd:            {}
      label:          {}
      legend:         {}
      li:             {}
      link:           { noClose: true }
      map:            {}
      mark:           {}
      menu:           {}
      meta:           { noClose: true, noId: true }
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
      title:          { noId: true }
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