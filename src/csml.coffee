coffee = require 'coffee-script'

csml = {}
html5 = null
html5Path = "./html5Plus"
defProp = Object.defineProperty
TemplateError = require('./errors').TemplateError
path = require 'path'
fs = require 'fs'

defProp csml, "html5",
  enumerable: true
  get: ->
    if not html5?
      html5 = require csml.html5Path
    return html5
  set: (value) ->
    html5 = value

defProp csml, "html5Path",
  enumerable: true
  get: ->
    html5Path
  set: (value) ->
    html5Path = value
    html5 = null
    
compile = csml.compile = (source, options={}) ->
  cache = compile.cache
  if (options.cacheSize or 1000) < cache.length
    diff = cache.length - options.cacheSize
    cache = compile.cache = cache.slice(diff)
    
  unless options.cache is false
    for item in cache
      if item[0] is source
        return item[1]
  
  # Compile our string to a function
  # Use `with` to access our local variables seamlessly
  if typeof source is "string"
    try
      dirname = options.filename.split '/'
      dirname.pop()
      options.dirname = dirname.join '/'
      js = coffee.compile source, bare: true
      lines = js.split "\n"
      withStmt = "with (options || {}) {"
      
      # Add with statement for magical access to variables
      for line, i in lines
        if not /\s+var\s+/.test line
          lines[i] = "with (this.templateContext) {\n#{line}"
          break
      lines[lines.length-1] += "\n}"
    
      js = lines.join "\n"
      # console.log js
      source = new Function js
    catch e
      throw new TemplateError "Error parsing #{options.filename}: #{e.message}"
  
  if options.isPartial
    options.nodeList = @html5.nodeList
    
  (options) => 
    try
      @html5.fragment source, options
    catch e
      throw new TemplateError "Error executing #{options.filename}: #{e.message}"

compile.cache = []

render = csml.render = (template, options) ->
  try
    options or= {}
    options.scope = options
    compiled = @compile template, options
    compiled options
  catch e
    throw new TemplateError "Error rendering #{options.filename}: #{e.message}"
  
module.exports = csml
  