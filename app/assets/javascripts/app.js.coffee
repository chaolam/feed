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
    feedView = App.FeedView.create()
    feedView.appendTo('#feed')
    self = @
    @initialAppids = appids
    $.when(FBMgr.fblogged_in).then(->
      self.set('selectedAppids', appids)
      App.postsController.loadPosts()
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

App.FeedView = Em.CollectionView.extend(
  itemViewClass:'App.PostView'
  contentBinding: 'App.postsController'
  arrayDidChange: (content, start, removed, added)-> 
    @_super(content, start, removed, added);
    Em.run.next(null,-> FB.XFBML.parse() if window.FB)
)

App.PostView = Em.View.extend(
  templateName:'post'
)

App.GameFilterView = Em.View.extend(
  tagName: 'li'
  classNameBindings: ['isSelected:active']
  click: ->
    content = this.get('content')
    App.filterGameController.set('filter', content)
  isSelected: Em.computed(->
    selected = App.filterGameController.filter
    selected == @content
  ).property('App.filterGameController.filter')
)

App.filterGameController = Em.Object.create(
  filter: App.allGamesObj
)

App.postsController = Em.ArrayController.create(
  content:[]
  lastChecked: null,
  selectedGameBinding: 'App.filterGameController.filter'
  init: ->
    App.filterGameController.addObserver('filter', $.proxy(@displayPosts, @))
    App.addObserver('selectedAppids', $.proxy(@selectedGamesChanged, @))
  selectedGamesChanged: ->
    Em.run.sync()
    @displayPosts() if @.get('selectedGame').isAllFeed
  loadPosts: ->
    args = {method:'stream.get',filter_key:'cg'}
    if @lastChecked
      args.start_time = @lastChecked
    else
      @set('content',[])
      $('#feed').addClass('fetching')
      args.limit = 200
    FB.api(args, $.proxy(@receivePosts, @))
  receivePosts: (r)->
    rfn(r)
    $('#feed').removeClass('fetching')
    posts = r.posts
    posts = posts.concat(@.friendPosts) if @lastChecked
    @lastChecked = r.posts[0].created_time if r && r.posts && r.posts[0]
    @.set('friendPosts', posts)
    @displayPosts()
  displayPosts: ->
    return unless @lastChecked
    appids = App.get('selectedAppids')
    posts = @friendPosts
    selectedGame = App.filterGameController.filter
    appPosts = posts.filter((post)-> selectedGame.get('appids').indexOf(post.app_id) != -1).slice(0,200)
    @set('content', appPosts.map((post)-> App.Post.create(post)))
)

App.gamesController = Em.ArrayController.create(
  content:[]
  init: -> 
    $.when(FBMgr.fblogged_in).then($.proxy(@queryMyPosts, @))
  queryMyPosts: ->
    $('#pop_content').addClass('fetching')
    FB.api({method:'fql.query',query:'select actor_id, created_time, app_id from stream where source_id=me() and actor_id=me() and type in (237, 272)'}, $.proxy(@receiveMyPosts,@))
  queryGamePosts: ->
    $('#pop_content').addClass('suggested')
    $('#pop_content').addClass('fetching')
    FB.api({method:'fql.query',query:'select actor_id, created_time, app_id from stream where filter_key="cg" limit 100'}, $.proxy(@filterPosts,@))
  filterPosts: (posts)->
    appIds = @appIds || []
    posts.forEach((post) -> if $.inArray(post.app_id, appIds)==-1 then appIds.push(post.app_id))
    @appIds = appIds
    @.set('content',appIds.map((appId)->App.Game.findByAppId(appId)))
    $('#pop_content').removeClass('fetching')
  receiveMyPosts: (posts)->
    if posts.length > 0
      @filterPosts(posts)
    else
      @queryGamePosts()
  save: (appids) ->
    App.set('selectedAppids', appids)
    $.post('/mygames', {appids:App.appidsStr()})
)

App.SelectGameView = Em.View.extend(
  templateName: 'select-games'
  tagName: 'div'
  elementId: 'selg'
  isVisible: false
  suggestMore: ->
    App.gamesController.queryGamePosts()
  close: ->
    @set('isVisible', false)
  save: ->
    @close()
    appids = $('#'+@elementId + ' input[type=checkbox]').filter((i,elt)->elt.checked).map((i,elt)->elt.id).toArray()
    App.gamesController.save(appids)
)

App.Post = Ember.Object.extend(
  title: Ember.computed(-> @attachment.name || @attachment.caption)
  picSrc: Ember.computed(->
    @attachment.media[0] && @attachment.media[0].src ||
      'http://graph.facebook.com/' + @actor_id + '/picture?type=square'
  )
  actionText: Ember.computed(-> @action_links && @action_links[0].text)
  postLink: Ember.computed(-> @attachment && @attachment.href || @action_links && @action_links[0].href)
  game_icon: Ember.computed(-> App.Game.findByAppId(@app_id).get('icon_url'))
  relative_time: Em.computed(-> new Date(@created_time*1000).toRelativeTime())
)

App.Game = Ember.Object.extend(
  init: ->
    @set('icon_url', '/games/' + @appid + '/icon')
    FB.api('/'+@appid, $.proxy(@receiveAppInfo, @))
  receiveAppInfo: (r)->
    @set('icon_url', r.icon_url)
    @set('name', r.name)
  appids: Em.computed(->[@appid]).property('appid')
)

App.Game.reopenClass(
  games: {}
  findByAppId: (appid)->
    if @games[appid]
      @games[appid]
    else
      @games[appid] = App.Game.create({appid:appid})
)