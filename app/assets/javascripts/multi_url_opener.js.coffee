@MultiUrlOpener = class MultiUrlOpener
  constructor: (urlObjs, options={})->
    @urlObjs = (obj for obj in urlObjs)
    @stepCB = options.stepCB
    @stepEndCB = options.stepEndCB
    @finalCB = options.finalCB
    @delay = options.delay || 10000
    leftOffset = options.leftOffset || 20
    topOffset = options.topOffset || 50
    @specs = options.windowSpecs ||
      "width=640,height=500, left=" + ((window.screenLeft||window.screenX)+leftOffset) + ",top=" +
      ((window.screenTop||window.screenY)+topOffset);
  start: ->
    @urlObj = @urlObjs.shift()
    if @urlObj
      firstUrl = @urlObj.getUrl()
      @popupWindow = window.open(firstUrl, '', this.specs)
      @stepCB(@urlObj) if (@stepCB)
      @timer = window.setInterval($.proxy(@next,@), @delay)
      @count = 1
  next: ->
    @prevObj = @urlObj
    @urlObj = @urlObjs.shift()
    if !@popupWindow.closed && @urlObj
      url = @urlObj.getUrl()
      @popupWindow.location = url
      ++@count
      @stepEndCB(@prevObj) if (@prevObj && @stepEndCB)
      @stepCB(@urlObj) if @stepCB
    else
      @popupWindow.close()
      window.clearInterval(@timer)
      @timer = null
      @stepEndCB(@prevObj) if (@prevObj && @stepEndCB)
      @finalCB(@count) if @finalCB
  pause: ->
    window.clearInterval(@timer)
    @timer = null
  resume: ->
    @next()
    @timer = window.setInterval($.proxy(@next,@), @delay)
  stop: ->
    @pause()
    @popupWindow.close()
    @finalCB(@count) if @finalCB
  isActive: ->
    @timer && @popupWindow && !@popupWindow.closed