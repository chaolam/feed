var rfn = function(r) {console.log('rfn',zz=r);};
var App = Em.Application.create();

App.PostListView = Em.View.extend({
});

App.Post = Ember.Object.extend({
  title: Ember.computed(function() {
    return this.attachment.caption || this.attachment.name;
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

Person = Ember.Object.extend({
  // these will be supplied by `create`
  firstName: null
});