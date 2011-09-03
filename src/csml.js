(function() {
  var coffee, compile, csml, defProp, html5, html5Path, render;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  csml = {};
  html5 = null;
  html5Path = __dirname + "./html5";
  defProp = Object.defineProperty;
  coffee = require('coffee-script');
  defProp(csml, "html5", {
    enumerable: true,
    get: function() {
      if (!(html5 != null)) {
        html5 = require(csml.html5Path);
      }
      return html5;
    },
    set: function(value) {
      return html5 = value;
    }
  });
  defProp(csml, "html5Path", {
    enumerable: true,
    get: function() {
      return html5Path;
    },
    set: function(value) {
      html5Path = value;
      return html5 = null;
    }
  });
  compile = csml.compile = function(source, options) {
    var cache, diff, item, js, lines, withStmt, _i, _len;
    cache = compile.cache;
    if (options.cacheSize < cache.length) {
      diff = cache.length - options.cacheSize;
      cache = compile.cache = cache.slice(diff);
    }
    if (options.cache !== false) {
      for (_i = 0, _len = cache.length; _i < _len; _i++) {
        item = cache[_i];
        if (item[0] === source) {
          return item[1];
        }
      }
    }
    if (typeof source === "string") {
      js = coffee.compile(source, {
        bare: true
      });
      lines = js.split("\n");
      withStmt = "with (options || {}) {";
      if (/^var/.test(lines[0])) {
        lines[0] = "" + lines[0] + "\n" + withStmt;
      } else {
        lines[0] = "" + withStmt + "\n" + lines[0];
      }
      lines[lines.length - 1] += "\n}";
      js = lines.join("\n");
      source = new Function("options", js);
    }
    return __bind(function(options) {
      return this.html5.fragment(source, options);
    }, this);
  };
  compile.cache = [];
  render = csml.render = function(template, options) {
    debugger;
    var compiled;
    options || (options = {});
    options.scope = this.html5;
    compiled = compile(template, options);
    return compiled(options);
  };
  module.exports = csml;
}).call(this);
