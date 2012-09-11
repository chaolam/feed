@rfn = (r)-> console.log('rfn', window.zz=r) if (window.console)
  
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
    appids = @get('selectedAppids')
    games = appids && appids.map((appid)->App.Game.findByAppId(appid)) || []
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
    @postsController().remove(post)
)

App.OneClickView = Em.View.extend(
  classNameBindings: ['active', 'paused','authorView', 'showCommentBox']
  authorViewBinding: 'App.authorView'
  active: false
  paused: false
  showCommentBoxBinding: 'App.oneClickController.showCommentBox'
  click: (event)->
    event.stopPropagation()
  start: ->
    posts = App.postsController().content.filter((p)-> !p.get('collapsed') && !p.get('removed'))
    App.muo = @muo = new MultiUrlOpener(posts, {
      delay: $('#gu_time')[0].value*1000,
      stepEndCB: (post)->
        post.set('collapsed', true)
        post.comment(App.oneClickController.get('comment'))
        App.removePost(post)
      finalCB: (count)=>
        @set('active', false)
        @set('paused', false)
        captionStr = 'Yay I just collected ' + count + ' bonuses in one click from ' +
          App.gamesController.selectedGamesString() + ' !'
        FB.ui({method:'feed',name:'View game feeds and collect bonuses easier', link:'http://apps.facebook.com/game_feeds/?fb_source=feedtitle', picture: 'http://images.coolchaser.com/gamecheats/giftbox.png', caption:captionStr, description:'You should try it too, you can view and collect your game bonuses so much easier!'})
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
  postCongrats: ->
  closeCommentBox: ->
    @set('showCommentBox', false)
)

App.EmptyView = Em.View.extend(
  templateName: 'no-posts'
)

App.AutoRefreshView = Em.View.extend(
  classNameBindings: ['isOn:on']
  isOn: true
  turnOff: ->
    @set('isOn', false)
    App.friendPostsController.setTimer(false)
    false
  turnOn: ->
    @set('isOn', true)
    App.friendPostsController.loadPosts()
    App.friendPostsController.setTimer(true)
    false
)

App.oneClickController = Em.Object.create(
  DefaultComment: "Helped with a lil assist from Game Feeds! http://apps.facebook.com/game_feeds"
  showCommentBox: false
  init: ->
    @_super()
    @set('leaveComment', $.cookie('leaveComment') == 'true')
    @set('comment', $.cookie('one_click_comment') || @DefaultComment)
    @addObserver('leaveComment', $.proxy(@leaveCommentChanged, @))
    @addObserver('comment', $.proxy(@commentChanged, @))
    $(document).ready(=>
      $(document.body).click(=>
        @set('showCommentBox', false)
      )
    )
  leaveCommentChanged: ->
    @set('comment', @DefaultComment) if @leaveComment
    $.cookie('leaveComment', @get('leaveComment'), {expires:365})
    if @get('leaveComment')
      FBMgr.withPermissionDo('publish_actions', =>
        @set('showCommentBox', true)
      )
    else
      @set('showCommentBox', false)
  commentChanged: ->
    $.cookie('one_click_comment', @get('comment'), {expires:365})
)