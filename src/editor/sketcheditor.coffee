"use strict"
# Pre dependencies
Editor = require("editor/editor")
require("util/primitive")

###*
@class SketchEditor
  Editor for sketch configuration (View)
@extends Editor
###
module.exports = class SketchEditor extends Editor
  Editor.register(this)

  #--------------------------------------------------------------------------------
  # Public properties
  #

  ###*
  @property {string} title
    Title of this editor
  @readonly
  ###
  @property("title", get: -> @sketch.friendlyName)

  #--------------------------------------------------------------------------------
  # Private variables
  #

  domElement = null
  jsTree = null
  jqTreeElement = null

  #--------------------------------------------------------------------------------
  # Public methods
  #

  ###*
  @method constructor
    Constructor
  @param {jQuery} $
    jQuery object
  @param {Sketch} sketch
    Sketch instance
  ###
  constructor: ($, sketch) ->
    super($, sketch, null, (domElement or= $("#sketch-editor")[0]))
    jsTree?.destroy()
    jqTreeElement = $(domElement).find(".explorer-left").empty()
    jqTreeElement.jstree({
      core:
        animation: 0
        check_callback: true
        themes:
          dots: false
      types:
        folder: {}
        sketch: {}
        file:
          icon: "glyphicon glyphicon-file"
      plugins: ["types"]
    })
    jsTree = jqTreeElement.jstree(true)
    e = "select_node.jstree"
    jqTreeElement.unbind(e).on(e, (event, data) =>
      isFile = (data.node.type == "file")
      $(".explorer-open").prop("disabled", !isFile)
      $(".explorer-rename").prop("disabled", !isFile)
      $(".explorer-remove").prop("disabled", !isFile)
      @_selectItem(@_itemNodes[data.node.id]?.item)
    )
    $(".explorer-add-existing").unbind("click")
      .click(@_addExisting.bind(this))
    $(".explorer-add").unbind("click")
      .click(@_addExisting.bind(this))
    $(".explorer-open").unbind("click")
      .click(@_openItem.bind(this))
    $(".explorer-rename").unbind("click")
      .click(@_renameItem.bind(this))
    $(".explorer-remove").unbind("click")
      .click(@_removeItem.bind(this))
    @_refreshTree()
    jsTree.select_node(@_rootNodeId)
    @sketch.addEventListener("additem", this)
    @sketch.addEventListener("removeitem", this)
    return

  #--------------------------------------------------------------------------------
  # Public methods
  #

  ###*
  @method
    Event handler
  @param {Object} event
    Event object
  @return {undefined}
  ###
  handleEvent: (event) ->
    switch event.type
      when "additem"
        @_refreshTree()
        for k, v of @_itemNodes
          if event.item.path == v.path
            jsTree.deselect_all()
            jsTree.select_node(k)
            break
      when "removeitem"
        @_refreshTree()
    return

  #--------------------------------------------------------------------------------
  # Private methods
  #

  ###*
  @private
  @method
    Add existing item
  @return {Promise}
    Promise object
  ###
  _addExisting: ->
    $ = @$
    fs = null
    name = null
    return AsyncFs.chooseFile().catch((error) =>
      # When cancelled
      App.warn(error)
      return
    ).then((result) =>
      return unless result?
      fs = result.fs
      name = result.name
      return "yes" unless @sketch.getItem(name)
      return global.bootbox.dialog_p({
        title: I18n.getMessage("File_overwrite")
        message: I18n.getMessage("Are_you_sure_to_replace_existing_file_1_with_new_one")
        closeButton: false
        buttons: {
          yes: {
            label: I18n.getMessage("Yes")
            className: "btn-danger"
          }
          no: {
            label: I18n.getMessage("No")
            className: "btn-success"
          }
        }
      })  # return global.bootbox.dialog_p()
    ).then((result) =>
      return unless result == "yes"
      @sketch.removeItem(name)
      return fs.readFile(name).then((data) =>
        return @sketch.addNewItem(name, data)
      )
    ) # return AsyncFs.chooseFile()...

  _openItem: ->
    return

  _renameItem: ->
    return

  _removeItem: ->
    return

  _selectItem: (item) ->
    div = @$(".explorer-right").empty()
      .append('<div class="col-sm-12"></div>').children("div")
    if item?
      # FIXME
    else
      # Root node (sketch)
      div.append("""
      <div class="panel panel-default">
        <div class="panel-heading">#{I18n.getMessage("Script_engine_config")}</div>
        <div class="panel-body">
          <label>#{I18n.getMessage("Script_to_execute_first")}</label>
          <div class="dropdown btn-group-justified">
            <button class="btn btn-default dropdown-toggle" data-toggle="dropdown"></button>
            <ul class="dropdown-menu">
            </ul>
          </div>
        </div>
      </div>
      """)
    return

  _refreshTree: ->
    # Update root node
    @_rootNodeId or= jsTree.create_node(null, {text: "", type: "sketch"})
    jsTree.rename_node(@_rootNodeId, @sketch.friendlyName)

    # Get items
    items = @sketch.items.sort((a, b) =>
      # Sort by path name (case insensitive)
      ap = a.path.toUpperCase()
      bp = b.path.toUpperCase()
      return -1 if ap < bp
      return +1 if ap > bp
      return 0
    )
    @_itemNodes or= {}

    # Remove invalid nodes
    idList = (k for k, v of @_itemNodes)
    for id in idList
      v = @_itemNodes[id]
      found = items.indexOf(v.item)
      if found < 0 or v.path != v.item.path
        jsTree.delete_node(id)
        delete @_itemNodes[id]

    # Add new nodes
    nextPos = 0
    for item in items
      nodeId = null
      for k, v of @_itemNodes
        if v.item == item
          nodeId = k
          break
      if nodeId
        # Already exists
        nextPos++
      else
        # New node
        nodeId = jsTree.create_node(@_rootNodeId, {
          text: item.path
          type: "file"
        }, nextPos++)
        @_itemNodes[nodeId] = {item: item, path: item.path}

    jsTree.open_node(@_rootNodeId)
    return

# Post dependencies
AsyncFs = require("filesystem/asyncfs")
App = require("app/app")
I18n = require("util/i18n")
