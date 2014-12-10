if (Meteor.isClient) {
  var map;
  var checkedItems = new Object();
  var navDep = new Deps.Dependency;
  var infowindow ;

  // disease selector helpers
  Template.diseaseSelector.helpers ({
    diseaseOpts: function(){
      var arr = Articles.find( {}, {fields: {'DiseaseName': 1}}).fetch();
      var distArr = _.uniq( arr, false, function(d){return d.DiseaseName} );
      
      for(var i=0 ; i<distArr.length ;i++)
      {
          distArr[i].DiseaseNameCap = capitaliseFirstLetter(distArr[i].DiseaseName);
      }
      
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
      var arr = Articles.find({ DiseaseName: { $in: disArray },
                             PublishTime: { $gte: start, $lt: end }
                           },
                           {sort : {PublishTime: -1} }).fetch();      
      for(var i=0 ; i<arr.length ; i++)
      {
        if(arr[i].Relevance){
          arr[i].Relevance = arr[i].Relevance.substring(0,4);      
        }
        // assign raw id
        arr[i].rid = arr[i]._id.toString().split("\"")[1];
      }
      return arr;
    }
  });
  
  // snippet detail events
  Template.snippetDetail.events = {
    'mouseover div[id^=snippet-]' : function(event, template){
      var eid = event.target.id;
      if(eid.indexOf("snippet-") > -1){
        var arr = eid.split("-");
        var disName = arr[1];
        var rid = arr[2];

        var marker = checkedItems[disName][rid];
        map.panTo(marker.getPosition());
        
      }
    }
  };

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
    //var maxTime = (new Date()).getTime();
    var maxTime = (new Date("2014-11-30")).getTime();
    var minTime = maxTime - 86400000*30;

    document.getElementById("slider-display").innerHTML = "<p>" + dateFormatter( new Date(minTime)) + " - " + dateFormatter( new Date(maxTime) ) + "</p>" ;

    if (! $('#slider-range').data('uiSlider')) {
      $( "#slider-range" ).slider({
        range: true,
        min: minTime,
        max: maxTime,
        step: 86400000,
        values: [ minTime, maxTime ],
        slide: function( event, ui ) {
            
          document.getElementById("slider-display").innerHTML = "<p>" + dateFormatter( new Date(ui.values[ 0 ])) + " - " + dateFormatter( new Date(ui.values[ 1 ])) + "</p>" ;
          
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
    
    infowindow = new google.maps.InfoWindow();
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
      var marker = markers[k];
      marker.setMap(map);
      
      if(map != null){
      // add event listerner for marker
        google.maps.event.addListener(marker, 'click', function(event) {
          map.panTo(this.getPosition());
        
          var rid = this.rid;

          // show info window 
          infowindow.close();
          var desc;
          if(this.loc == "NULL"){
            desc = "<p class=\"gray_font\">"+this.dis+"</p>";
          }else{
            desc = "<p class=\"gray_font\">"+this.dis+" in "+this.loc+"</p>";          
          }
          infowindow.setContent("<div class=\"infobox\"><h4>" + this.title + "</h4>"+desc+"</div>");
          infowindow.open(map, this);
        
          // scroll to the snippet 
          $("#panel-footer").animate({ 
            scrollTop: $( "div[data-id="+rid+"]" ).position().top
          }, 600);
        }); 
      }
      // remove event listerner
      
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
        var rid = subArticles[i]['_id'].toString().split("\"")[1] ;
        var lat = subArticles[i]['Lat'];
        var lng = subArticles[i]['Lng'];
        var image = '/images/red.png';
        //console.log( "id=" + id + " lat=" + lat + " lng=" + lng );
        markers[ rid ] = new google.maps.Marker({
          position: new google.maps.LatLng( lat, lng ),
          animation: google.maps.Animation.DROP,
          map: map,
          rid: rid,
          title: subArticles[i]['Title'],
          loc: subArticles[i]['Location'],
          dis: subArticles[i]['DiseaseName'],
          icon: image
        });
      }
      return markers;
  }

  function dateFormatter(d){
    return d.getFullYear() + "/" + (d.getMonth()+1) + "/" + d.getDate();
  }

  // reference: http://goo.gl/u2zyk
  function capitaliseFirstLetter(string)
  {
    return string.charAt(0).toUpperCase() + string.slice(1);
  }
  
}

