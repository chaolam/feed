App.FeedView = Em.CollectionView.extend(
  itemViewClass:'App.PostView'
  fetching: true
  hasNoPosts: false
  classNameBindings:['fetching', 'hasNoPosts']
  init: ->
    @_super()
    Em.run.sync()
    App.addObserver('authorView', $.proxy(@checkVisibility,@))
    @checkVisibility()
    @get('content').addObserver('lastChecked', $.proxy(@checkFetching,@))
    @get('content').addObserver('hasPosts', $.proxy(@checkHasPosts,@))
  arrayDidChange: (content, start, removed, added)-> 
    @_super(content, start, removed, added);
    Em.run.next(null,-> FB.XFBML.parse() if window.FB)
  checkVisibility: ->
    @set('isVisible', App.get('authorView') == @.get('content').get('author'))
  checkFetching: ->
    @.set('fetching', !@get('content').get('lastChecked'))
  checkHasPosts: ->
    @set('hasNoPosts', !@get('content').get('hasPosts'))
)

App.PostView = Em.View.extend(
  templateName:'post'
  removeMe:->
    @set('isVisible', false)
    App.removePost(@get('content'))
)

App.FriendOrMeView = Em.View.extend(
  isMe: ->
    App.set('authorView', 'me')
  isFriend: ->
    App.set('authorView', 'friends')
)
    
App.PostsController = Em.ArrayController.extend(
  content:[]
  lastChecked: null
  hasPosts: true
  author: 'unknown'
  lastDisplay: 0
  selectedGameBinding: 'App.filterGameController.filter'
  dontShowLinksBinding: 'App.dontShowLinks'
  posts: []
  init: ->
    App.filterGameController.addObserver('filter', $.proxy(@gameFilterChanged, @))
    App.addObserver('selectedAppids', $.proxy(@selectedGamesChanged, @))
    @timer = window.setInterval((=>@loadPosts()), 60000) if @doTimer
  gameFilterChanged: ->
    window.clearTimeout(@lastDisplayTimer) if @lastDisplayTimer
    @lastDisplayTimer = @lastDisplay = 0
    @displayPosts()
  selectedGamesChanged: ->
    Em.run.sync()
    @displayPosts() if @.get('selectedGame').isAllFeed
  showable: (post)->
    posts = @get('posts') || []
    !posts.some((aPost)->aPost.identical(post)) && !@get('dontShowLinks').contains(post.get('postLink'))
  loadPosts: ->
    console.log('PostController#loadPosts should not be called!')
  receivePosts: (posts)->
    posts = posts.map((rawPost)->App.Post.create(rawPost))
    posts = posts.filter((post)=> @showable(post)) 
    console.log('rp', posts.length)
    posts = posts.concat(@posts) if @lastChecked
    posts = posts.sort((a,b)->b.created_time - a.created_time).slice(0,400)
    @set('lastChecked', posts && posts[0] && posts[0].created_time || parseInt(Date.now()/1000))
    @set('posts', posts)
    @displayPosts()
  displayPosts: ->
    return unless @lastChecked
    if Date.now() < (@lastDisplay+5000)
      if !@lastDisplayTimer
        @lastDisplayTimer = window.setTimeout($.proxy(@displayPosts, @), Date.now() - @lastDisplay + 5000)
      return
    appids = App.get('selectedAppids')
    posts = @get('posts')
    selectedGame = App.filterGameController.filter
    appPosts = posts.filter((post)-> selectedGame.get('appids').indexOf(post.app_id) != -1)
    if appPosts.length > 0
      @lastDisplay = Date.now()
      @lastDisplayTimer = null
    @set('content', appPosts)
    @set('hasPosts', appPosts.length > 0)
)

App.friendPostsController = App.PostsController.create(
  author: 'friends'
  doTimer: true
  initialLoad: ->
    @loadPosts()
    @loadPosts(200)
    window.setTimeout(=>
      App.get('selectedAppids').forEach((appid)=>@loadAppPost(appid))
    ,2000)
  loadPosts: (limit=0)->
    args = {method:'stream.get',filter_key:'cg'}
    if !limit && @lastChecked
      args.start_time = @lastChecked
    else
      args.limit = limit if limit
    FB.api(args, $.proxy(@receiveStreamPosts, @))
  loadAppPost: (appid)->
    FB.api({method:'stream.get',filter_key:'app_'+appid}, $.proxy(@receiveStreamPosts, @))
  receiveStreamPosts: (r)->
    console.log('fpc no posts!', r) if (!r.posts)
    @receivePosts(r.posts)
  removePost: (post)->
    
)

App.myPostsController = App.PostsController.create(
  author: 'me'
  loadPosts: ->
    FB.api({method:'fql.query',query:'select actor_id, created_time, app_id, attachment, action_links from stream where source_id=me() and actor_id=me() and type in (237, 272)'}, $.proxy(@receivePosts,@))
)
    
App.Post = Ember.Object.extend(
  row: true
  collapsed: false
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
  getUrl: ->
    @.get('postLink')
)
  