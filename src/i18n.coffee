###*
@class I18n
  Internationalization helper class
###
class I18n
  lang = chrome.i18n.getUILanguage()

  ###*
  @static
  @property {string} lang
    UI language name
  @readonly
  ###
  Object.defineProperty(this, "lang", {value: lang})

  ###*
  @method constructor
    Constructor of multi-language text
  ###
  constructor: (@_obj) ->
    return

  ###*
  @method
    Get text of this multi-language text
  @return {string}
    Translated text
  ###
  toString: ->
    return @_text if @_text?
    do =>
      @_text = @_obj
      return if typeof(@_text) == "string"
      @_text = @_obj[lang]
      return if typeof(@_text) == "string"
      @_text = @_obj["en"]
      return if typeof(@_text) == "string"
      @_text = "<translate error>"
      console.warn("No translated text for object (#{@_obj})")
    return @_text

  ###*
  @static
  @method
    Get translated message (using chrome.i18n)
  @param {string} id
    ID of message
  @param {string[]} [subs]
    Substitute text
  @return {string}
    Translated message
  ###
  @getMessage: (id, subs...) ->
    r = chrome.i18n.getMessage(id, subs...)
    if r == ""
      console.warn("No translation for id='#{id}'")
      r = id.replace(/_/g, " ")
    return r

  ESCAPE = {"<": "{", ">": "}"}

  ###*
  @static
  @method
    Make error object with translated message
  @param {string} id
    ID of message
  @param {string[]} [subs]
    Substitute text
  @return {Error}
    Error object
  ###
  @error: (id, subs...) ->
    return Error(@getMessage(id, subs...))

  ###*
  @static
  @method
    Make Promise.reject object with translated message
  @param {string} id
    ID of message
  @param {string[]} [subs]
    Substitute text
  @return {Promise}
    Promise object
  ###
  @rejectPromise: (id, subs...) ->
    return Promise.reject(@error(id, subs...))

  ###*
  @static
  @method
    Translate messages in text
  @param {string} text
    Input text
  @return {string}
    Output (translated) text
  ###
  @translateText: (text) ->
    r = text
    r = r.replace(/{(\w+)(\/?)}/g, (n, p1, p2) =>
      m = @getMessage(p1)
      m = m.replace(/\.+$/, "") if p2 == "/"
      return m
    )
    r = r.replace(/{([<>])}/g, (n, p1) => ESCAPE[p1])
    return r

  CONVATTRS = ["innerHTML", "title"]

  ###*
  @static
  @method
    Translate elements in document
  @param {Document} doc
    Document
  @return {undefined}
  ###
  @translateDocument: (doc) ->
    for e in doc.getElementsByClassName("i18n")
      e[a] = @translateText(e[a]) for a in CONVATTRS
    return

module.exports = I18n
