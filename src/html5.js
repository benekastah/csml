(function() {
  var AttributeList, Element, Html5, Node, NodeList, TextNode, trim;
  var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  }, __slice = Array.prototype.slice, __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  if (String.prototype.trim != null) {
    trim = function(str) {
      return String.prototype.trim.call(str);
    };
  } else {
    trim = function(str) {
      return str.replace(/^\s*/, '').replace(/\s*$/, '');
    };
  }
  Node = (function() {
    function Node(itemString) {
      this.itemString = itemString;
    }
    Node.prototype.toString = function() {
      return "" + this.itemString;
    };
    return Node;
  })();
  NodeList = (function() {
    __extends(NodeList, Array);
    function NodeList() {
      var item, items, _i, _len;
      items = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      for (_i = 0, _len = items.length; _i < _len; _i++) {
        item = items[_i];
        this.push(item);
      }
    }
    NodeList.prototype.toString = function() {
      var item, ret, _i, _len;
      ret = '';
      for (_i = 0, _len = this.length; _i < _len; _i++) {
        item = this[_i];
        ret = "" + ret + (item.toString());
      }
      return ret;
    };
    return NodeList;
  })();
  AttributeList = (function() {
    function AttributeList(attrs) {
      var attr, data, dataRe, eventRe, name, newName, noId;
      if (attrs == null) {
        attrs = {};
      }
      data = attrs.data;
      if (data instanceof Object) {
        this.data = data.data;
      }
      noId = attrs.noId;
      delete attrs.noId;
      if (!noId) {
        this.id = attrs.id || AttributeList.id();
      }
      dataRe = /^data\-/;
      eventRe = /^on/;
      for (name in attrs) {
        if (!__hasProp.call(attrs, name)) continue;
        attr = attrs[name];
        if (dataRe.test(name)) {
          this.data || (this.data = {});
          this.data[newName = name.replace(dataRe, '')] = attr;
        } else if (eventRe.test(name) && typeof attr === "function") {
          AttributeList.eventHandlers[this.id] = attr;
        } else {
          if (!this[name]) {
            this[name] = attr;
          }
        }
      }
    }
    AttributeList.id = function() {
      return "__generated_id_" + (this.id.index++);
    };
    AttributeList.id.index = 0;
    AttributeList.prototype.toString = function() {
      var name, ret, value, _ref;
      ret = '';
      for (name in this) {
        if (!__hasProp.call(this, name)) continue;
        value = this[name];
        ret += (name !== "data" || !(this.data instanceof Object) ? "" + name + "='" + value + "' " : '');
      }
      _ref = this.data || {};
      for (name in _ref) {
        if (!__hasProp.call(_ref, name)) continue;
        value = _ref[name];
        ret += "data-" + name + "='" + value + "' ";
      }
      return trim(ret);
    };
    AttributeList.eventHandlers = {};
    return AttributeList;
  })();
  Element = (function() {
    __extends(Element, Node);
    function Element(config) {
      var attributes;
      this.tag = config.tag, attributes = config.attributes, this.selfClosing = config.selfClosing, this.nodeList = config.nodeList;
      this.attributeList = new Element.AttributeList(attributes);
      Element.__super__.constructor.call(this, this.toString());
    }
    Element.prototype.toString = function() {
      var close, contents, nl, open;
      open = "\n" + trim("<" + this.tag + " " + this.attributeList + ">");
      nl = this.nodeList[0] instanceof TextNode ? '\n' : '';
      contents = ("" + nl + this.nodeList + "\n").replace(/\n/g, "\n  ").replace(/[ ]{2}$/, '');
      close = "</" + this.tag + ">";
      return "" + open + contents + close;
    };
    Element.AttributeList = AttributeList;
    return Element;
  })();
  TextNode = (function() {
    __extends(TextNode, Node);
    function TextNode(text) {
      this.text = text != null ? text : '';
      TextNode.__super__.constructor.call(this, this.text);
    }
    TextNode.empty = new TextNode();
    return TextNode;
  })();
  /*
      Here is our grand Html5 class
      More documentation to come, once the API is a bit more finished
    */
  Html5 = (function() {
    function Html5() {
      var defaultConfig, isContents, tag, _fn, _ref;
      isContents = function(candidate) {
        return typeof candidate === "string" || typeof candidate === "function" || candidate instanceof Element || candidate instanceof TextNode;
      };
      _ref = this.tags;
      _fn = __bind(function(tag, defaultConfig) {
        return this[tag] = function(attrs, contents) {
          var defaultVal, defineContents, name, tmp, _ref2, _ref3, _ref4;
          if (isContents(attrs) && arguments.length < 2) {
            _ref2 = [attrs, contents], contents = _ref2[0], attrs = _ref2[1];
          }
          attrs || (attrs = {});
          for (name in defaultConfig) {
            if (!__hasProp.call(defaultConfig, name)) continue;
            defaultVal = defaultConfig[name];
            if (!(attrs[name] != null)) {
              attrs[name] = defaultVal;
            }
          }
          contents || (contents = TextNode.empty);
          if (typeof contents === "string") {
            contents = new TextNode(contents);
          }
          if (contents instanceof TextNode || contents instanceof Element) {
            contents = new NodeList(contents);
          } else if (typeof contents === "function") {
            if (tag === "script") {
              contents = new TextNode("(" + contents + ")();");
              contents = new NodeList(contents);
            } else {
              _ref3 = [contents, new NodeList()], defineContents = _ref3[0], contents = _ref3[1];
              _ref4 = [this.nodeList, contents], tmp = _ref4[0], this.nodeList = _ref4[1];
              defineContents.call(this);
              this.nodeList = tmp;
            }
          }
          return this.nodeList.push(new Element({
            tag: tag,
            attributes: attrs,
            nodeList: contents
          }));
        };
      }, this);
      for (tag in _ref) {
        if (!__hasProp.call(_ref, tag)) continue;
        defaultConfig = _ref[tag];
        _fn(tag, defaultConfig);
      }
    }
    Html5.prototype.document = function(definitionFn, config) {
      return this.fragment(function() {
        this.DOCTYPE(5);
        return this.html(__bind(function() {
          return definitionFn.call(this);
        }, this));
      }, config);
    };
    Html5.prototype.fragment = function(definitionFn, config) {
      var ret;
      this.nodeList = new NodeList;
      definitionFn.call(this, config);
      ret = this.nodeList;
      delete this.nodeList;
      return ret.toString();
    };
    Html5.Element = Element;
    Html5.TextNode = TextNode;
    Html5.Node = Node;
    Html5.NodeList = NodeList;
    Html5.AttributeList = AttributeList;
    Html5.prototype.text = function(txt) {
      return this.nodeList.push(new TextNode(txt));
    };
    Html5.prototype.comment = function(message) {
      return this.nodeList.push(new Node("\n\n<!-- " + message + " -->"));
    };
    Html5.prototype.DOCTYPE = (function() {
      var doctype;
      doctype = new Node("<!DOCTYPE html>");
      return function() {
        return this.nodeList.push(doctype);
      };
    })();
    Html5.prototype.tags = {
      a: {},
      abbr: {},
      address: {},
      area: {},
      article: {},
      aside: {},
      audio: {},
      b: {},
      base: {},
      bdo: {},
      blockquote: {},
      body: {
        noId: true
      },
      br: {
        noId: true
      },
      button: {},
      canvas: {},
      caption: {},
      cite: {},
      code: {},
      col: {},
      colgroup: {},
      command: {},
      datalist: {},
      dd: {},
      del: {},
      details: {},
      dfn: {},
      div: {},
      dl: {},
      dt: {},
      em: {},
      embed: {},
      fieldset: {},
      figcaption: {},
      figure: {},
      footer: {},
      form: {},
      h1: {},
      h2: {},
      h3: {},
      h4: {},
      h5: {},
      h6: {},
      head: {
        noId: true
      },
      header: {},
      hgroup: {},
      hr: {
        noId: true
      },
      html: {
        noId: true
      },
      i: {},
      iframe: {},
      img: {},
      input: {},
      ins: {},
      keygen: {},
      kbd: {},
      label: {},
      legend: {},
      li: {},
      link: {},
      map: {},
      mark: {},
      menu: {},
      meta: {},
      meter: {},
      nav: {},
      noscript: {},
      object: {},
      ol: {},
      optgroup: {},
      option: {},
      output: {},
      p: {},
      param: {},
      pre: {},
      progress: {},
      q: {},
      rp: {},
      rt: {},
      ruby: {},
      s: {},
      samp: {},
      script: {},
      section: {},
      select: {},
      small: {},
      source: {},
      span: {},
      strong: {},
      style: {},
      sub: {},
      summary: {},
      sup: {},
      table: {},
      tbody: {},
      td: {},
      textarea: {},
      tfoot: {},
      th: {},
      thead: {},
      time: {},
      title: {},
      tr: {},
      ul: {},
      "var": {},
      video: {},
      wbr: {}
    };
    return Html5;
  })();
  if ((typeof process !== "undefined" && process !== null ? process.title : void 0) === "node") {
    module.exports = new Html5();
  } else {
    this.Html5 = new Html5();
  }
}).call(this);
