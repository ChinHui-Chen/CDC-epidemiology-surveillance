Articles = new Mongo.Collection("articles");
var map;
var checkedItems = new Object();

if (Meteor.isClient) {

  // footer events
  Template.footer.events = {
    'click #insertMarker' : function(){
      updateMarkers( 'birdflu', 1, '2010/01/01', new Date(), '10' );
    },
    'click #removeMarker' : function(){
      updateMarkers( 'birdflu', -1, '', '', '' );
    }
  };

  // initialize google maps
  GoogleMaps.init(
    {
    'key': 'AIzaSyDeHmf_9sSp9dT0T8x_bST6rbxTtvSgetA',
    'language': 'en'
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

  // function to update mark
  // query: the disease to insert/remove (ignore if flag=0)
  // flag: 1 stands for addition, -1 stands for deletion, 0 stands for the same query
  // startTime: the timestamp of start time
  // endTime: the timestamp of end time
  // num: the number of records in each query
  function updateMarkers(query, flag, startTime, endTime, num ){

    // addition
    if(flag == 1){
      // add markers
      var markers = queryToMarkers(query, startTime, endTime, num);
      setAllMap( markers, map );
      checkedItems[ query ] = markers;
    }
    // deletion
    else if(flag == -1){
      // remove markers
      var tempMarker = checkedItems[ query ] ;
      setAllMap( tempMarker, null );

      // delete from hash
      checkedItems[ query ] = {};
      delete checkedItems[ query ];

      //console.log( JSON.stringify(checkedItems) );
    }
    // the same
    else if(flag == 0){
      // refresh markers

    }
    // exception
    else{
      throw "invalid flag parameter";
    }
  }

  function setAllMap(markers, map){
    for (var k in markers){
      markers[k].setMap(map);
    }
  }

  function queryToMarkers(query, startTime, endTime, num){
      var markers = new Object();
      var start = new Date(startTime);
      var end = new Date(endTime);

      // get articles from db
      var subArticles = Articles.find( { DiseaseName: query,
                                         PublishTime: {$gte: start, $lt: end} }
                                      ).fetch();

      // translate to markers
      for(var i=0 ; i<subArticles.length ; i++)
      {
        var id = subArticles[i]['_id'] ;
        var lat = subArticles[i]['Lat'];
        var lng = subArticles[i]['Lng'];

        //console.log( "id=" + id + " lat=" + lat + " lng=" + lng );
        markers[ id ] = new google.maps.Marker({
          position: new google.maps.LatLng( lat, lng ),
          map: map
        });
      }
      return markers;
  }

}

if (Meteor.isServer) {
  Meteor.startup(function () {

    /*
    Articles.insert({
      DiseaseName: "birdflu",
      Source: "CNN",
      Title: "bird flu title cnn",
      Snippet: "bird flu snippet cnn",
      Url: "www.cnn.com",
      Language: "en",
      Location: "Taiwan",
      Lat: "23",
      Lng: "120",
      PublishTime: new Date(),
      CrawlTime: new Date()
    });

    Articles.insert({
      DiseaseName: "birdflu",
      Source: "BBC",
      Title: "bird flu title bbc",
      Snippet: "bird flu snippet bbc",
      Url: "www.bbc.com",
      Language: "en",
      Location: "Japan",
      Lat: "24",
      Lng: "121",
      PublishTime: new Date(),
      CrawlTime: new Date()
    });
   */
  });
}
