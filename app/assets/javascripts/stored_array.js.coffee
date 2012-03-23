@StoredArray = class StoredArray
  constructor: (@key, @maxSize=200)->
    @hasStorage = !!window.localStorage
    @data = if @hasStorage then JSON.parse(localStorage.getItem(@key)) || [] else []
  getData: -> @data
  add: (item)->
    @data.unshift(item)
    @data = @data.slice(0,@maxSize)
    localStorage.setItem(@key, JSON.stringify(@data)) if @hasStorage
  contains: (item)->
    @data.some((elt)->elt == item)
    
    