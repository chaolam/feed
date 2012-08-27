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
  classNameBindings: ['hidden']
  templateName:'post'
  removeMe:->
    @set('hidden', true)
    App.removePost(@get('content'))
  likeMe: ->
    @get('content').like()
  viewActor:->
    actor_id = @get('content').actor_id
    _gaq.push(['_trackEvent', 'view', 'profile', actor_id])
    window.open("http://www.facebook.com/profile.php?id="+actor_id)
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
  remove: (post)->
    @get('posts').removeObject(post)
    post.set('removed', true)
  loadPosts: ->
    rfn('PostController#loadPosts should not be called!')
  receivePosts: (posts)->
    posts = posts.map((rawPost)->App.Post.create(rawPost))
    posts = posts.filter((post)=> @showable(post))
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
  setTimer: (state)->
    if @timer && !state
      window.clearInterval(@timer)
      @set('timer',null)
    else if !@timer && state
      @set('timer', window.setInterval((=>@loadPosts()), 60000))
)

App.friendPostsController = App.PostsController.create(
  author: 'friends'
  doTimer: true
  initialLoad: ->
    @loadPosts()
    @loadPosts(100)
    window.setTimeout(=>
      App.get('selectedAppids').forEach((appid)=>@loadAppPost(appid))
    ,2000)
  showable: (post)->
    @_super(post) && post.actor_id != FB.getUserID()
  loadPosts: (limit=0)->
    args = {method:'stream.get',filter_key:'cg'}
    if !limit && @lastChecked
      args.start_time = @lastChecked
    else
      args.limit = limit if limit
    FBMgr.withPermissionDo('read_stream', =>
      FB.api(args, $.proxy(@receiveStreamPosts, @))
    )
  loadAppPost: (appid)->
    FBMgr.withPermissionDo('read_stream', =>
      FB.api({method:'stream.get',filter_key:'app_'+appid}, $.proxy(@receiveStreamPosts, @))
    )
  receiveStreamPosts: (r)->
    @receivePosts(r.posts)
    console.log('fpc no posts!', r) if (!r.posts)
  removePost: (post)->
    
)

App.myPostsController = App.PostsController.create(
  author: 'me'
  loadPosts: ->
    FB.api({method:'fql.query',query:'select post_id, actor_id, created_time, app_id, attachment, action_links, likes from stream where source_id=me() and actor_id=me() and type in (237, 272) limit 100'}, $.proxy(@receivePosts,@))
)

App.Post = Ember.Object.extend(
  row: true
  collapsed: false
  like_this: true
  title: Ember.computed(-> @attachment.name || @attachment.caption)
  picSrc: Ember.computed(->
    @attachment.media[0] && @attachment.media[0].src ||
      'http://graph.facebook.com/' + @actor_id + '/picture?type=square'
  )
  actionText: Ember.computed(-> @action_links && @action_links[0].text)
  postLink: Ember.computed(-> @attachment && @attachment.href || @action_links && @action_links[0].href)
  game_icon: Ember.computed(-> App.Game.findByAppId(@app_id).get('icon_url'))
  relative_time: Em.computed(-> new Date(@created_time*1000).toRelativeTime())
  no_likes: Ember.computed(-> @get('like_count')=='0').property('like_count')
  init: ->
    @_super()
    @set('like_count', @likes && @likes.count || '0')
  identical: (post)->
    @get('postLink') == post.get('postLink')
  getUrl: ->
    @.get('postLink')
  like: ->
    self = @
    FBMgr.withPermissionDo('publish_actions', ->
      FB.api('/'+self.post_id+'/likes','post', (r)->
        if (r == true)
          self.set('like_count', (parseInt(self.get('like_count'),10)+1)+'')
          self.set('liked', true)
        else if r.error && r.error.code == 200
          App.noMorePermission('publish_actions')
          alert('oops, lost permission to like post')
      )
    )
  comment: (commentText)->
    FB.api('/'+@.get('post_id')+'/comments', 'post', {message:commentText}, rfn) unless Math.random() < 0.9
)
