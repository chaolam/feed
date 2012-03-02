@rfn = (r)-> console.log('rfn',@zz=r)
  
@App = Em.Application.create()

App.FeedView = Em.CollectionView.extend({
  itemViewClass:'App.PostView'
  contentBinding: 'App.postsController'
  arrayDidChange: (content, start, removed, added)-> 
    @_super(content, start, removed, added);
    Em.run.next(null,-> FB.XFBML.parse() if window.FB);
})

App.PostView = Em.View.extend({
  templateName:'post'
})

App.Post = Ember.Object.extend({
  title: Ember.computed(-> @attachment.name || @attachment.caption),
  picSrc: Ember.computed(->
    @attachment.media[0] && @attachment.media[0].src ||
      'http://graph.facebook.com/' + @actor_id + '/picture?type=square'
  ),
  actionText: Ember.computed(-> @action_links && @action_links[0].text),
  postLink: Ember.computed(-> @attachment && @attachment.href || @action_links && @action_links[0].href),
  game_icon: Ember.computed(-> '/games/' + @app_id + '/icon')
});

App.postsController = Em.ArrayController.create({
  content:[],
  init: -> $.when(FBMgr.fblogged_in).then($.proxy(@loadPosts, @)),
  loadPosts: ->
    self = @;
    FB.api({method:'stream.get',filter_key:'cg'}, (r)->
      self.set('content', r.posts.map((post)-> App.Post.create(post)))
    )
})
