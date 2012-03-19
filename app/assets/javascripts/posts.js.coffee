App.FeedView = Em.CollectionView.extend(
  itemViewClass:'App.PostView'
  contentBinding: Em.Binding.oneWay('App.friendPostsController')
  arrayDidChange: (content, start, removed, added)-> 
    @_super(content, start, removed, added);
    Em.run.next(null,-> FB.XFBML.parse() if window.FB)
)

App.PostView = Em.View.extend(
  templateName:'post'
)

App.FriendOrMeView = Em.View.extend(
  isMe: ->
    App.feedView.bind('content', Em.Binding.oneWay('App.myPostsController'))
    true
  isFriend: ->
    App.feedView.bind('content', Em.Binding.oneWay('App.friendPostsController'))
    true
)
    
App.PostsController = Em.ArrayController.extend(
  content:[]
  lastChecked: null,
  selectedGameBinding: 'App.filterGameController.filter'
  posts: []
  init: ->
    App.filterGameController.addObserver('filter', $.proxy(@displayPosts, @))
    App.addObserver('selectedAppids', $.proxy(@selectedGamesChanged, @))
  selectedGamesChanged: ->
    Em.run.sync()
    @displayPosts() if @.get('selectedGame').isAllFeed
  loadPosts: ->
    console.log('PostController#loadPosts should not be called!')
  receivePosts: (posts)->
    rfn(posts)
    posts = posts.concat(@posts) if @lastChecked
    @lastChecked = posts[0].created_time if posts && posts[0]
    @set('posts', posts)
    @displayPosts()
  displayPosts: ->
    return unless @lastChecked
    $('#feed').removeClass('fetching')
    appids = App.get('selectedAppids')
    posts = @.get('posts')
    selectedGame = App.filterGameController.filter
    appPosts = posts.filter((post)-> selectedGame.get('appids').indexOf(post.app_id) != -1).slice(0,200)
    @set('content', appPosts.map((post)-> App.Post.create(post)))
)

App.friendPostsController = App.PostsController.create(
  loadPosts: ->
    args = {method:'stream.get',filter_key:'cg'}
    if @lastChecked
      args.start_time = @lastChecked
    else
      @set('content',[])
      $('#feed').addClass('fetching')
      args.limit = 200
    FB.api(args, $.proxy(@receiveStreamPosts, @))
  receiveStreamPosts: (r)->
    @receivePosts(r.posts)
)

App.myPostsController = App.PostsController.create(
  loadPosts: ->
    $('#feed').addClass('fetching') unless @lastChecked
    FB.api({method:'fql.query',query:'select actor_id, created_time, app_id, attachment from stream where source_id=me() and actor_id=me() and type in (237, 272)'}, $.proxy(@receivePosts,@))
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
  