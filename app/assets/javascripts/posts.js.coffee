App.FeedView = Em.CollectionView.extend(
  itemViewClass:'App.PostView'
  contentBinding: 'App.friendPostsController'
  arrayDidChange: (content, start, removed, added)-> 
    @_super(content, start, removed, added);
    Em.run.next(null,-> FB.XFBML.parse() if window.FB)
)

App.PostView = Em.View.extend(
  templateName:'post'
)

App.friendPostsController = Em.ArrayController.create(
  content:[]
  lastChecked: null,
  selectedGameBinding: 'App.filterGameController.filter'
  friendPosts: []
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
    posts = posts.concat(@friendPosts) if @lastChecked
    @lastChecked = r.posts[0].created_time if r && r.posts && r.posts[0]
    @.set('friendPosts', posts)
    @displayPosts()
  displayPosts: ->
    return unless @lastChecked
    appids = App.get('selectedAppids')
    posts = @.get('friendPosts')
    selectedGame = App.filterGameController.filter
    appPosts = posts.filter((post)-> selectedGame.get('appids').indexOf(post.app_id) != -1).slice(0,200)
    @set('content', appPosts.map((post)-> App.Post.create(post)))
)

App.myPostsController = Em.ArrayController.create(
  content: []
  selectedGameBinding: 'App.filterGameController.filter'
  myPosts: []
  lastChecked: null
  init: ->
    App.filterGameController.addObserver('filter', $.proxy(@displayPosts, @))
    App.addObserver('selectedAppids', $.proxy(@selectedGamesChanged, @))
  selectedGamesChanged: ->
    Em.run.sync()
    @displayPosts() if @.get('selectedGame').isAllFeed
  loadPosts: ->
    FB.api({method:'fql.query',query:'select actor_id, created_time, app_id from stream where source_id=me() and actor_id=me() and type in (237, 272)'}, $.proxy(@receivePosts,@))
  receivePosts: (posts)->
    rfn(posts)
    posts = posts.concat(@myPosts) if @lastChecked
    @lastChecked = posts[0].created_time if posts && posts[0]
    @set('myPosts', posts)
    @displayPosts()
  displayPosts: ->
    return unless @lastChecked
    appids = App.get('selectedAppids')
    posts = @.get('myPosts')
    selectedGame = App.filterGameController.filter
    appPosts = posts.filter((post)-> selectedGame.get('appids').indexOf(post.app_id) != -1).slice(0,200)
    @set('content', appPosts.map((post)-> App.Post.create(post)))
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
  