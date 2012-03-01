var rfn = function(r) {console.log('rfn',zz=r);};;
var App = Em.Application.create();

App.FeedView = Em.CollectionView.extend({
  itemViewClass:'App.PostView',
  contentBinding: 'App.postsController',
  arrayDidChange: function(content, start, removed, added) {
    this._super(content, start, removed, added);
    Em.run.next(null,function() {if (window.FB) {FB.XFBML.parse();}});
  }
});

App.PostView = Em.View.extend({
  templateName:'post'
});

App.Post = Ember.Object.extend({
  title: Ember.computed(function() {
    return this.attachment.name || this.attachment.caption;
  }),
  picSrc: Ember.computed(function() {
    return this.attachment.media[0] && this.attachment.media[0].src ||
      'http://graph.facebook.com/' + this.actor_id + '/picture?type=square';
  }),
  actionText: Ember.computed(function() {
    return this.action_links && this.action_links[0].text;
  }),
  postLink: Ember.computed(function() {
    return this.attachment && this.attachment.href || this.action_links && this.action_links[0].href;
  }),
  game_icon: Ember.computed(function() {
    return '/games/' + this.app_id + '/icon';
  })
});

App.postsController = Em.ArrayController.create({
  content:[],
  init: function() {
    $.when(FBMgr.fblogged_in).then($.proxy(this.loadPosts, this));
  },
  loadPosts: function() {
    var self = this;
    FB.api({method:'stream.get',filter_key:'cg'}, function(r) {
      self.set('content', r.posts.map(function(post) {return App.Post.create(post);}));
    });
  }
});

