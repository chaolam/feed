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

App.gamesController = Em.ArrayController.create(
  content:[]
  init: -> 
    $.when(FBMgr.fblogged_in).then($.proxy(@queryMyPosts, @))
  queryMyPosts: ->
    $('#pop_content').addClass('fetching')
    FB.api({method:'fql.query',query:'select actor_id, created_time, app_id from stream where source_id=me() and actor_id=me() and type in (237, 272) limit 100'}, $.proxy(@receiveMyPosts,@))
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
    $('#pop_content').addClass('no_games') if @appIds.length == 0
  receiveMyPosts: (posts)->
    if posts.length > 0
      @filterPosts(posts)
    else
      @queryGamePosts()
  save: (appids) ->
    App.set('selectedAppids', appids)
    $.post('/mygames', {appids:App.appidsStr()})
  selectedGamesString: ->
    if App.filterGameController.filter == App.allGamesObj
      App.get('selectedGames').slice(1).map((g)->g.name).join(', ')
    else
      App.filterGameController.filter.name
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