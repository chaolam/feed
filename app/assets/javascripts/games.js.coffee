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
  searchResults:[]
  selectedAppidsBinding: 'App.selectedAppids'
  init: -> 
    $.when(FBMgr.fblogged_in).then($.proxy(@queryMyPosts, @))
  currentGames: Em.computed(->
    appids = @get('selectedAppids')
    if appids
      appids.map((appid)->
        game = App.Game.findByAppId(appid)
        game.set('selected', true)
        game
      )
    else
      []
  ).property('selectedAppids').cacheable()
  queryMyPosts: ->
    $('#pop_content').addClass('fetching')
    FB.api({method:'fql.query',query:'select actor_id, created_time, app_id from stream where source_id=me() and actor_id=me() and type in (237, 272) limit 100'}, $.proxy(@receiveMyPosts,@))
  queryGamePosts: ->
    $('#pop_content').addClass('suggested')
    $('#pop_content').addClass('fetching')
    FB.api({method:'fql.query',query:'select actor_id, created_time, app_id from stream where filter_key="cg" limit 100'}, $.proxy(@filterPosts,@))
  filterPosts: (posts)->
    appIds = @appIds || []
    posts.forEach((post) =>
      if $.inArray(post.app_id, appIds)==-1  
        appIds.push(post.app_id)
    )
    @appIds = appIds
    @.set('content', appIds.map((appId)->
      game = App.Game.findByAppId(appId)
      game.set('selected', true)
      game
    ))
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
  queryBinding: 'App.gamesController.query'
  searchResultsBinding: 'App.gamesController.searchResults'
  suggestMore: ->
    App.gamesController.queryGamePosts()
  close: ->
    @set('isVisible', false)
  save: ->
    @close()
    appids = $('#'+@elementId + ' input[type=checkbox]').filter((i,elt)->elt.checked).map((i,elt)->elt.id).toArray()
    App.gamesController.save(appids)
  search: ->
    window.x = this
    $.ajax({url:'/games/search',data:{query:@get('query')}}).done((data)=>
      @set('searchResults', App.Game.receiveGames(data))
    )
)

App.Game = Ember.Object.extend(
  init: ->
    if !@icon_url
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
  receiveGames: (data)->
    data.map((gameData)=>
      if @games[gameData.appid]
        @games[gameData.appid]
      else
        @games[gameData.appid] = App.Game.create(gameData)
    )
)

App.GameSelectorView = Em.View.extend(
  templateName:'game-selector'
)