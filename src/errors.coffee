
class @TemplateError extends Error
  constructor: (@message) ->
    Error.call this, @message
    Error.captureStackTrace this, arguments.callee
  name: "TemplateError"