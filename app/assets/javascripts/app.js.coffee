@rfn = (r)-> console.log('rfn',@zz=r)
  
@App = Em.Application.create(
  selectedAppids: null
  authorView: 'friends'
  dontShowLinks: new StoredArray('dontshowlinks')
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
    @friendFeedView = App.FeedView.create(contentBinding:'App.friendPostsController')
    @friendFeedView.appendTo('#feed')
    @myFeedView = App.FeedView.create(contentBinding:'App.myPostsController')
    @myFeedView.appendTo('#feed')
    @initialAppids = appids
    $.when(FBMgr.fblogged_in).then(=>
      @set('selectedAppids', appids)
      App.friendPostsController.initialLoad()
      App.myPostsController.loadPosts()
    )
  appidsStr: ->
    @selectedAppids.join(',')
  ready: ->
    @selectGameView = App.SelectGameView.create()
    @selectGameView.appendTo('body')
    @selectGameView.set('isVisible', @initialAppids.length == 0)
  showGameSelector: ->
    @selectGameView.set('isVisible', true)
  postsController: ->
    if @get('authorView') == 'friends' then App.friendPostsController else App.myPostsController
  removePost: (post)->
    @get('dontShowLinks').add(post.get('postLink'))
)

App.OneClickView = Em.View.extend(
  classNameBindings: ['active', 'paused','authorView']
  authorViewBinding: 'App.authorView'
  active: false
  paused: false
  start: ->
    posts = App.postsController().content
    App.muo = @muo = new MultiUrlOpener(posts, {
      stepEndCB: (post)->
        post.set('collapsed', true)
        App.removePost(post)
      finalCB: =>
        @set('active', false)
        @set('paused', false)
    })
    @muo.start()
    @set('active', true)
  pause:->
    @muo.pause()
    @set('paused', true)
  resume:->
    @muo.resume()
    @set('paused', false)
  stop: ->
    @muo.stop()
    @set('active', false)
    @set('paused', false)
)

App.EmptyView = Em.View.extend(
  templateName: 'no-posts'
)
