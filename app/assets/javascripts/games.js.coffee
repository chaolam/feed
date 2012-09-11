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
  currentGames: []
  selectedAppidsBinding: 'App.selectedAppids'
  init: -> 
    @addObserver('selectedAppids', $.proxy(@calcCurrentGames, @))
    $.when(FBMgr.fblogged_in).then($.proxy(@queryMyPosts, @))
  calcCurrentGames: ->
    appids = @get('selectedAppids')
    currentGames = if appids then App.Game.findAllByAppIds(appids) else []
    currentGames.forEach((game)->game.set('selected', true))
    @set('currentGames', currentGames)
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
    games = App.Game.findAllByAppIds(appIds)
    @set('content', this.removeDuplicates(games))
    $('#pop_content').removeClass('fetching')
    $('#pop_content').addClass('no_games') if @appIds.length == 0
  receiveMyPosts: (posts)->
    if posts.length > 0
      @filterPosts(posts)
    else
      @queryGamePosts()
  save: () ->
    appids = @get('currentGames').filterProperty('selected').mapProperty('appid')
    App.set('selectedAppids', appids)
    $.post('/mygames', {appids:App.appidsStr()})
  selectedGamesString: ->
    if App.filterGameController.filter == App.allGamesObj
      App.get('selectedGames').slice(1).map((g)->g.name).join(', ')
    else
      App.filterGameController.filter.name
  removeDuplicates: (games)->
    games.filter((game)=>!@get('currentGames').contains(game))
  setSearchResults: (searchedGames)->
    @set('searchResults', this.removeDuplicates(searchedGames))
  addGame: (game)->
    if !@get('currentGames').contains(game)
      game.set('selected', true)
      currentGames = @get('currentGames').copy()
      currentGames.push(game)
      @set('currentGames', currentGames)
    @set('searchResults', @searchResults.copy().without(game))
    @set('content', @content.copy().without(game))
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
    App.gamesController.save()
    @close()
  search: ->
    window.x = this
    $.ajax({url:'/games/search',data:{query:@get('query')}}).done((data)=>
      App.gamesController.setSearchResults(App.Game.receiveGames(data))
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
  findAllByAppIds: (ids)->
    if ids
      this.findByAppId(id) for id in ids
    else
      []
)

App.GameSelectorView = Em.View.extend(
  templateName:'game-selector'
  add: ->
    App.gamesController.addGame(@game)
    console.log('added: ', @game.name)
)
