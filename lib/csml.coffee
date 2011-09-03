csml = {}
html5 = null
html5Path = __dirname + "/../support/html5"
defProp = Object.defineProperty
coffee = require 'coffee-script'

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
    
compile = csml.compile = (source, options) ->
  cache = compile.cache
  if options.cacheSize < cache.length
    diff = cache.length - options.cacheSize
    cache = compile.cache = cache.slice(diff)
    
  unless options.cache is false
    for item in cache
      if item[0] is source
        return item[1]
  
  # Compile our string to a function
  # Use `with` to access our local variables seamlessly
  if typeof source is "string"
    js = coffee.compile source, bare: true
    lines = js.split "\n"
    
    withStmt = "with (options || {}) {"
    if /^var/.test lines[0]
      lines[0] = "#{lines[0]}\n#{withStmt}"
    else
      lines[0] = "#{withStmt}\n#{lines[0]}"
    lines[lines.length-1] += "\n}"
    
    js = lines.join "\n"
    source = new Function "options", js
  
  (options) => @html5.fragment source, options

compile.cache = []

render = csml.render = (template, options) ->
  debugger
  options or= {}
  options.scope = @html5
  compiled = compile(template, options)
  compiled(options)
  
module.exports = csml
  