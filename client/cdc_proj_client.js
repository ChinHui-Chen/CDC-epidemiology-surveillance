if (Meteor.isClient) {
  var map;
  var checkedItems = new Object();
  var navDep = new Deps.Dependency;

  // disease selector helpers
  Template.diseaseSelector.helpers ({
    diseaseOpts: function(){
      var arr = Articles.find( {}, {fields: {'DiseaseName': 1}}).fetch();
      var distArr = _.uniq( arr, false, function(d){return d.DiseaseName} );
      return distArr;
    }
  });

  // snippet list helpers
  Template.snippetList.helpers ({
    snippets: function(){
      // set depend var
      navDep.depend();

      // get query from checkedItems
      var disArray = Object.keys(checkedItems) ;
      var start = new Date( $("#slider-range").slider("values")[0] );
      var end = new Date( $("#slider-range").slider("values")[1] );
      return Articles.find({ DiseaseName: { $in: disArray },
                             PublishTime: { $gte: start, $lt: end }
                           },
                           {sort : {PublishTime: -1} });
    }
  });

  // diseaseSelector events
  Template.diseaseSelector.events = {
    'change input.disSelector' : function(event, template){
      if( event.target.checked ){
        updateMarkers( event.target.value, 1, $("#slider-range").slider("values")[0], $("#slider-range").slider("values")[1], '' );
      }else{
        updateMarkers( event.target.value, -1, '', '', '' );
      }
    }
  };

  // diseaseSelector rendered
  Template.diseaseSelector.rendered = function(){
    var maxTime = (new Date()).getTime();
    var minTime = maxTime - 86400000*30;

    if (! $('#slider-range').data('uiSlider')) {
      $( "#slider-range" ).slider({
        range: true,
        min: minTime,
        max: maxTime,
        step: 86400000,
        values: [ minTime, maxTime ],
        slide: function( event, ui ) {
          $( "#amount" ).val( dateFormatter( new Date(ui.values[ 0 ])) + " - " + dateFormatter( new Date(ui.values[ 1 ])) );
          updateMarkers( '', 0, ui.values[0], ui.values[1], '' );
        }
      });
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
    }
    // the same
    else if(flag == 0){
      // refresh markers
      for(var key in checkedItems ){
        var markers = queryToMarkers(key, startTime, endTime, num);

        // remove current remarks
        setAllMap( checkedItems[key], null );
        checkedItems[key] = {};
        // add new remarks
        setAllMap( markers, map );
        checkedItems[key] = markers;
      }
    }
    // exception
    else{
      throw "invalid flag parameter";
    }

    // update snippet list
    updateSnippetList();
  }

  function updateSnippetList(){
    navDep.changed();
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

      console.log(subArticles.length);
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

  function dateFormatter( d ){
    return d.getFullYear() + "/" + d.getMonth() + "/" + d.getDate();
  }

}

