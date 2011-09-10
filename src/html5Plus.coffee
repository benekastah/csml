csml = require './csml'
html5 = require './html5'
fs = require 'fs'
defProp = Object.defineProperty

module.exports = html5Plus = Object.create html5

html5Plus.register = (path) ->
  path = path.split '/'
  name = path[path.length-1]
  path = path.join '/'
  path = if @widgetsDir and not /^\//.test path then "#{@widgetsDir}/#{path}" else path
  @[name] = (config) ->
    try
      results = require path
    catch e
      results = {}
    if typeof results == "object"
      (config[name] = value if not config[name]?) for own name, value of results
      
    ["#{path}/index.csml", config]

widgetsDir = null
defProp html5Plus, "widgetsDir", {
  enumerable: true
  get: -> widgetsDir
  set: (path) ->
    fs.readdir path, (err, contents) ->
      html5Plus.register item for item in contents
    widgetsDir = path
}