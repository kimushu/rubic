# Dependencies
JSONable = require("./jsonable")
I18n = require("./i18n")

###*
@class Sketch
  Sketch (Model)
@extends JSONable
###
class Sketch extends JSONable
  null

  #--------------------------------------------------------------------------------
  # Public properties
  #

  ###*
  @property {string} friendlyName
    Name of sketch (Same as directory name)
  @readonly
  ###
  @property("friendlyName", get: -> @_dirFs?.name)

  ###*
  @property {boolean} modified
    Is sketch modified
  @readonly
  ###
  @property("modified", get: -> @_modified)

  ###*
  @property {AsyncFs} dirFs
    File system object for sketch directory
  @readonly
  ###
  @property("dirFs", get: -> @_dirFs)

  #--------------------------------------------------------------------------------
  # Event listeners
  #

  ###*
  @event onChange
    Changed event target
  @param {Sketch} sketch
    The instance of sketch
  @return {void}
  ###
  @property("onChange", get: -> @_onChange)

  #--------------------------------------------------------------------------------
  # Private constants
  #

  SKETCH_FILE = "sketch.json"

  #--------------------------------------------------------------------------------
  # Public methods
  #

  ###*
  @static
  @method
    Create empty sketch on temporary storage
  @return {Promise}
    Promise object
  @return {Sketch} return.PromiseValue
    The instance of sketch
  ###
  @createNew: ->
    fs = null
    return AsyncFs.requestTemporary().then((result) =>
      fs = result
      return 1
    )

  ###*
  @static
  @method
    Open sketch
  @param {AsyncFs} dirFs
    File system object at the sketch directory
  @return {Promise}
    Promise object
  @return {Sketch} return.PromiseValue
    The instance of sketch
  ###
  @open: (dirFs) ->
    dirFs.readFile(SKETCH_FILE).then((data) =>
      sketch = JSONable.parseJSON(data)
      return Promise.reject(I18n("Invalid_sketch_json")) unless sketch instanceof Sketch
      sketch._dirFs = dirFs
      return sketch
    )

  ###*
  @method
    Save sketch
  @param {AsyncFs} [newDirFs]
    File system object to store sketch
  @return {Promise}
    Promise object
  ###
  save: (newDirFs) ->
    if newDirFs?
      # Update properties
      oldDirFs = @_dirFs
      @_dirFs = newDirFs
    return @_files.reduce(
      # Save all files in sketch
      (promise, file) =>
        return file.editor.save() if file.editor?
        return unless newDirFs?
        # Relocate file
        return oldDirFs.readFile(f.path).then((data) =>
          return newDirFs.writeFile(file.path, data)
        )
      Promise.resolve()
    ).then(=>
      # Save sketch settings
      @_rubicVersion = chrome.runtime.getManifest().version
      return newDirFs.writeFile(SKETCH_FILE, @toJSON())
    ).then(=>
      # Successfully saved
      @_modified = false
      return  # Last PromiseValue
    ).catch((error) =>
      # Revert properties
      @_dirFs = oldDirFs if newDirFs?
      return Promise.reject(error)
    ) # return @_files.reduce().then()...

  ###*
  @method
    Get files in sketch (except for SKETCH_FILE)
  @return {string[]}
    Array of path of files
  ###
  getFiles: ->
    return (file.path for file in @_files)

  ###*
  @method
    Open (or activate) an editor for file
  @param {string} path
    Path of file
  @param {jQuery} $
    jQuery object
  @param {Function} [editorClass]
    Constructor of editor class (auto detect if omitted)
  @return {Promise}
    Promise object
  @return {Editor} return.PromiseValue
    The instance of new editor
  ###
  openEditor: (path, $, editorClass) ->
    file = @_files.find((f) -> f.path == path)
    return Promise.reject(Error("No_such_file_in_project")) unless file?
    return Promise.resolve(
    ).then(=>
      if file.editor?
        return if file.editor.constructor == editorClass
        return Promise.reject(Error("Close_existing_editor_before_open_new_editor"))
      editorClass or= Editor.findEditor(path)
      return Promise.reject(Error("Suitable_editor_not_found")) unless editorClass?
      file.editor = new editorClass($, this, path)
    ).then(=>
      file.editor.activate()
      return file.editor
    )
    return

  #--------------------------------------------------------------------------------
  # Protected methods
  #

  ###*
  @protected
  @method constructor
    Constructor of Sketch class
  @param {Object} obj
    JSON object
  ###
  constructor: (obj) ->
    super(obj)
    @_rubicVersion = obj.rubicVersion
    return

module.exports = Sketch
