if (Meteor.isClient) {

  GoogleMaps.init(
    {
    'key': 'AIzaSyDeHmf_9sSp9dT0T8x_bST6rbxTtvSgetA', //optional
    'language': 'en' //optional
  },

  function(){
    var mapOptions = {
      zoom: 2,
      mapTypeId: google.maps.MapTypeId.SATELLITE
    };
    map = new google.maps.Map(document.getElementById("map-canvas"), mapOptions);
    map.setCenter(new google.maps.LatLng( 23.363556, 120.730438 ));
  }
  );
}

if (Meteor.isServer) {
  Meteor.startup(function () {
    // code to run on server at startup
  });
}
