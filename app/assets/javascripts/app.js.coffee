@rfn = (r)-> console.log('rfn',@zz=r)
  
@App = Em.Application.create()

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

App.postsController = Em.ArrayController.create(
  content:[]
  init: -> $.when(FBMgr.fblogged_in).then($.proxy(@loadPosts, @))
  loadPosts: ->
    self = @;
    FB.api({method:'stream.get',filter_key:'cg'}, (r)->
      self.set('content', r.posts.map((post)-> App.Post.create(post)))
    )
)

App.gamesController = Em.ArrayController.create(
  content:[]
  active: true
  init: -> 
    $.when(FBMgr.fblogged_in).then($.proxy(@queryMyPosts, @))
  queryMyPosts: ->
    FB.api({method:'fql.query',query:'select actor_id, created_time, app_id from stream where source_id=me() and actor_id=me() and type in (237, 272)'}, $.proxy(@filterPosts,@))
  queryGamePosts: ->
    FB.api({method:'fql.query',query:'select actor_id, created_time, app_id from stream where filter_key="cg" limit 100'}, $.proxy(@filterPosts,@))
  filterPosts: (posts)->
    appIds = @appIds || []
    posts.forEach((post) -> if $.inArray(post.app_id, appIds)==-1 then appIds.push(post.app_id))
    @appIds = appIds
    @.set('content',appIds.map((appId)->App.Game.findByAppId(appId)))
)

App.SelectGameView = Em.View.extend(
  tagName: 'div'
  elementId: 'selg'
  classNameBindings: ['active']
  activeBinding: 'App.gamesController.active'
)

App.Post = Ember.Object.extend(
  title: Ember.computed(-> @attachment.name || @attachment.caption)
  picSrc: Ember.computed(->
    @attachment.media[0] && @attachment.media[0].src ||
      'http://graph.facebook.com/' + @actor_id + '/picture?type=square'
  )
  actionText: Ember.computed(-> @action_links && @action_links[0].text)
  postLink: Ember.computed(-> @attachment && @attachment.href || @action_links && @action_links[0].href)
  game_icon: Ember.computed(-> App.Game.findByAppId(@app_id).get('iconUrl'))
)

App.Game = Ember.Object.extend(
  init: ->
    @set('icon_url', '/games/' + @appid + '/icon')
    FB.api('/'+@appid, $.proxy(@receiveAppInfo, @))
  receiveAppInfo: (r)->
    @set('icon_url', r.icon_url)
    @set('name', r.name)
)

App.Game.reopenClass(
  games: {}
  findByAppId: (appid)->
    if @games[appid]
      @games[appid]
    else
      @games[appid] = App.Game.create({appid:appid})
)