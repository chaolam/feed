App.FeedView = Em.CollectionView.extend(
  itemViewClass:'App.PostView'
  fetching: true
  classNameBindings:['fetching']
  init: ->
    @_super()
    Em.run.sync()
    App.addObserver('authorView', $.proxy(@checkVisibility,@))
    @checkVisibility()
    @.get('content').addObserver('lastChecked', $.proxy(@checkFetching,@))
  arrayDidChange: (content, start, removed, added)-> 
    @_super(content, start, removed, added);
    Em.run.next(null,-> FB.XFBML.parse() if window.FB)
  checkVisibility: ->
    @set('isVisible', App.get('authorView') == @.get('content').get('author'))
  checkFetching: ->
    @.set('fetching', !@get('content').get('lastChecked'))
)

App.PostView = Em.View.extend(
  templateName:'post'
)

App.FriendOrMeView = Em.View.extend(
  isMe: ->
    App.set('authorView', 'me')
  isFriend: ->
    App.set('authorView', 'friends')
)
    
App.PostsController = Em.ArrayController.extend(
  content:[]
  lastChecked: null,
  author: 'unknown'
  selectedGameBinding: 'App.filterGameController.filter'
  posts: []
  init: ->
    App.filterGameController.addObserver('filter', $.proxy(@displayPosts, @))
    App.addObserver('selectedAppids', $.proxy(@selectedGamesChanged, @))
    @timer = window.setInterval($.proxy(@loadPosts,@), 60000)
  selectedGamesChanged: ->
    Em.run.sync()
    @displayPosts() if @.get('selectedGame').isAllFeed
  hasPost: (post)->
    posts = @get('posts') || []
    !posts.some((aPost)->aPost.identical(post))
  loadPosts: ->
    console.log('PostController#loadPosts should not be called!')
  receivePosts: (posts)->
    self = @
    posts = posts.map((rawPost)->App.Post.create(rawPost))
    posts = posts.filter((post)-> self.hasPost(post)) 
    rfn(posts.length)
    posts = posts.concat(@posts) if @lastChecked
    @set('lastChecked', posts[0].created_time) if posts && posts[0]
    @set('posts', posts)
    @displayPosts()
  displayPosts: ->
    return unless @lastChecked
    appids = App.get('selectedAppids')
    posts = @get('posts')
    selectedGame = App.filterGameController.filter
    appPosts = posts.filter((post)-> selectedGame.get('appids').indexOf(post.app_id) != -1).slice(0,200)
    @set('content', appPosts)
)

App.friendPostsController = App.PostsController.create(
  author: 'friends'
  loadPosts: ->
    args = {method:'stream.get',filter_key:'cg'}
    if @lastChecked
      args.start_time = @lastChecked
    else
      @set('content',[])
      args.limit = 50
    FB.api(args, $.proxy(@receiveStreamPosts, @))
  receiveStreamPosts: (r)->
    @receivePosts(r.posts)
)

App.myPostsController = App.PostsController.create(
  author: 'me'
  loadPosts: ->
    FB.api({method:'fql.query',query:'select actor_id, created_time, app_id, attachment, action_links from stream where source_id=me() and actor_id=me() and type in (237, 272)'}, $.proxy(@receivePosts,@))
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
  identical: (post)->
    @get('postLink') == post.get('postLink')
)
  