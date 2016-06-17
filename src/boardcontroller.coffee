# Pre dependencies
WindowController = require("./windowcontroller")
Board = null
Preferences = null

AUTO_PAGE_TRANSITION = 500

###*
@class BoardController
  Controller for board-catalog view (Controller, Singleton)
@extends Controller
###
class BoardController extends WindowController
  null
  instance = null

  #--------------------------------------------------------------------------------
  # Public properties
  #

  ###*
  @static
  @property {BoardController}
    The instance of this class
  @readonly
  ###
  @classProperty("instance", get: ->
    return instance or= new BoardController(window)
  )

  #--------------------------------------------------------------------------------
  # Public methods
  #

  ###*
  @method constructor
    Constructor of MainController class
  @param {Window} window
    window object
  ###
  constructor: (window) ->
    super(window)
    @_board = null
    return

  #--------------------------------------------------------------------------------
  # Protected methods
  #

  ###*
  @inheritdoc Controller#onActivated
  ###
  onActivated: ->
    super
    outer = @$(".main-outer.when-board")
    bodies = outer.children(".config-body").hide()
    header = outer.children(".config-header")
    header.find("a").click((event) =>
      id = @$(event.target).parents("li")[0].id
      return unless id.startsWith("board-")
      header.find("li.active").removeClass("active")
      header.find("li##{id}").addClass("active")
      for b in bodies
        tab = @$(b)
        if tab.hasClass(id)
          tab.show()
        else
          tab.hide()
    )
    @_refreshCatalog()
    @$(".board-use-this").click((event) =>
      li = @$(event.target).parents(".media")
      name = li[0].id?.split?("-")[1]
      li.siblings().removeClass("board-selected")
      li.addClass("board-selected")
      for board in Board.subclasses
        continue unless board.name == name
        # overwrite confirmation
        @_board = new board()
        @_refreshFeatures()
        if AUTO_PAGE_TRANSITION?
          setTimeout((=> @$("li#board-features > a").click()), AUTO_PAGE_TRANSITION)
        break
    )
    @$("body").addClass("controller-board")
    return

  ###*
  @inheritdoc Controller#onDeactivated
  ###
  onDeactivated: ->
    @$("body").removeClass("controller-board")
    outer = @$(".main-outer.when-board")
    header = outer.children(".config-header")
    header.find("a").unbind("click")
    @$(".board-use-this").unbind("click")
    super
    return

  #--------------------------------------------------------------------------------
  # Private methods
  #

  ###*
  @private
  @method
    Refresh catalog page
  @return {undefined}
  ###
  _refreshCatalog: ->
    Board or= require("./board")
    tmpl = @$("#board-catalog-tmpl")
    return if tmpl.css("display") == "none"
    tmpl.hide()
    tmpl.siblings().remove()
    for board in Board.subclasses
      id = "board-#{board.name}"
      li = @$("##{id}")
      (li = tmpl.clone()).appendTo(tmpl.parent()) unless li[0]
      li[0].id = id
      li.find(".media-object")[0].src = board.images[0]
      li.find(".media-heading .placeholder").text(board.friendlyName)
      ph = li.find(".media-body > p .placeholder")
      @$(ph[0]).text(board.description)
      @$(ph[1]).text(board.author)
      @$(ph[2]).attr("href", board.website)
      li.show()
      li.addClass("board-selected") if @_board?.constructor.name == board.name
    return

  ###*
  @private
  @method
    Refresh features
  @return {Promise}
    Promise object
  ###
  _refreshFeatures: ->
    return Promise.resolve() unless @_board?
    return Promise.resolve(
    ).then(=>
      @$("#feature-board").text(@_board.constructor.friendlyName)
      return @_board.getCatalog(true)
    ).then((catalog) =>
      tmpl = @$("#script-engine-tmpl")
      tmpl.hide()
      tmpl.siblings().remove()
      for e in catalog.engines
        id = "engine-#{e.id}"
        (li = tmpl.clone()).appendTo(tmpl.parent())
        li[0].id = id
        li.find(".placeholder").text(e.name)
        li.find(".label-danger").hide() unless e.obsolete
        li.find(".label-warning").hide() unless e.beta
        li.show()
      tmpl.siblings.children("a").click((event) =>
      )
      tmpl = @$("#firmware-tmpl")
      tmpl.hide()
    )
    return

module.exports = BoardController

# Post dependencies
I18n = require("./i18n")
