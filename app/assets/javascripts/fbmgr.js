var FBMgr = {
  init: function(appId, channelUrl) {
    this.appId = appId;
    this.channelUrl = channelUrl;
    this.fbinit_deferred = $.Deferred();
    this.fblogged_in = $.Deferred();
    window.fbAsyncInit = $.proxy(this.fbInit_cb, this);
    (function(d){
       var js, id = 'facebook-jssdk', ref = d.getElementsByTagName('script')[0];
       if (d.getElementById(id)) {return;}
       js = d.createElement('script'); js.id = id; js.async = true;
       js.src = "//connect.facebook.net/en_US/all.js";
       ref.parentNode.insertBefore(js, ref);
     }(document));
  },
  fbInit_cb: function() {
    FB.init({appId:this.appId, status: true, cookie: true, xfbml:true, channelUrl:this.channelUrl});
    this.fbinit_deferred.resolve();
    FB.getLoginStatus($.proxy(this.handleFBSession, this));
  },
  handleFBSession: function(r) {
    if (r.authResponse) {
      this.fblogged_in.resolve();
    }
  }
};
