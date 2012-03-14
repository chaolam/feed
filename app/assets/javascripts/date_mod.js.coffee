Date.now = -> newDate().getTime() unless Date.now

Date.prototype.toRelativeTime = (now_threshold)->
  delta = new Date() - this
  now_threshold = parseInt(now_threshold || 60000)
  now_threshold = 60000 if isNaN(now_threshold)
  return 'mere moments ago' if delta <= now_threshold
  
  currentUnit = null
  conversions = 
    millisecond: 1
    second: 1000
    minute: 60
    hour: 60
    day: 24
    month: 30 #roughly
    year: 12
  for unit, time of conversions
    if delta < time
      break
    else
      currentUnit = unit
      delta = delta/time
  delta = Math.floor(delta)
  currentUnit = currentUnit + 's' if delta != 1
  return [delta, currentUnit, 'ago'].join(' ')