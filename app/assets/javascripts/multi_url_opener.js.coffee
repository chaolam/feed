class MultiUrlOpener
  constructor: (@urls, options={})
    @stepCB = options.stepCB
    @stepEndCB = options.stepEndCB
    @finalCB = options.finalCB
    @delay = options.delay || 10000
    leftOffset = options.leftOffset || 20
    topOffset = options.topOffset || 50
    @specs = options.windowSpecs ||
      "width=640,height=500, left=" + ((window.screenLeft||window.screenX)+leftOffset) + ",top=" +
      ((window.screenTop||window.screenY)+topOffset);
    @index = 0
  start: ->
    firstUrl = @urls.shift()
    if firstUrl
      @popupWindow = window.open(firstUrl, '', this.specs)
      @stepCB(0) if (@stepCB)
      @timer = window.setInterval($.proxy(@next,@), @delay)
      ++@index
  next: ->
    url = @urls.shift()
    if !@popupWindow.closed && url
      @popupWindow.location = url
      @stepEndCB(@index-1) if (@index > 0 && @stepEndCB)
      @stepCB(@index) if @stepCB
      ++@index
    else
      @popupWindow.close()
      window.clearInterval(@timer)
      @timer = null
      @finalCB() if @finalCB
  pause: ->
    window.clearInterval(@timer)
    @timer = null
  resume: ->
    @next()
    @timer = window.setInterval($.proxy(@next,@), @delay)
  isActive: ->
    @timer && @popupWindow && !@popupWindow.closed