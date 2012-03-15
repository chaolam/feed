@rfn = (r)-> console.log('rfn',@zz=r)
  
@App = Em.Application.create(
  selectedAppids: null
  allGamesObj: Em.Object.create(
    name:'All Feed'
    isAllFeed: true
    appidsBinding: 'App.selectedAppids'
  )
  selectedGames: Em.computed(->
    appids = @.get('selectedAppids')
    games = (appids && appids.map((appid)->App.Game.findByAppId(appid)) || [])
    games.unshift(App.allGamesObj)
    games
  ).property('selectedAppids').cacheable()
  appInit: (appids)->
    @feedView = App.FeedView.create()
    @feedView.appendTo('#feed')
    self = @
    @initialAppids = appids
    $.when(FBMgr.fblogged_in).then(->
      self.set('selectedAppids', appids)
      App.friendPostsController.loadPosts()
    )
  appidsStr: ->
    @selectedAppids.join(',')
  ready: ->
    @selectGameView = App.SelectGameView.create()
    @selectGameView.appendTo('body')
    @selectGameView.set('isVisible', @initialAppids.length == 0)
  showGameSelector: ->
    @selectGameView.set('isVisible', true)
)

