# https://developer.mozilla.org/ja/docs/Web/JavaScript/Reference/Global_Objects/Array/find
unless Array::find
  Array::find = (predicate, thisArg) ->
    if this == null
      throw new TypeError("Array.prototype.find called on null or undefined")
    if typeof(predicate) != "function"
      throw new TypeError("predicate must be a function")
    list = Object(this)
    for value, i in list
      return value if predicate.call(thisArg, value, i, list)
    return undefined

# https://developer.mozilla.org/ja/docs/Web/JavaScript/Reference/Global_Objects/String/endsWith
unless String::endsWith
  String::endsWith = (searchString, position) ->
    subjectString = @toString()
    if (typeof(position) != number) or
       (!isFinite(position)) or
       (Math.floor(position) != position) or
       (position > subjectString.length)
      position = subjectString.length
    position -= searchString.length
    lastIndex = subjectString.indexOf(searchString, position)
    return lastIndex != -1 and lastIndex == position

# https://developer.mozilla.org/ja/docs/Web/JavaScript/Reference/Global_Objects/String/startsWith
unless String::startsWith
  String::startsWith = (searchString, position) ->
    position ||= 0
    return @substr(position, searchString.length) == searchString

