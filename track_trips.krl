ruleset track_trips {
  meta {
    name "Track Trips"
    description <<A first ruleset for single pico part 3>>
    author "Scott McKenzie"
    logging on
    shares trips, long_trips, short_trips
    provides long_trips, short_trips
  }
  
global {
  trips = function(){
      ent:trips
  }
  
  long_trips = function(){
      ent:long_trips
  }
  
  short_trips = function(){
      ent:trips.filter(function(k,v){ent:trips{k} != ent:long_trips{k}})
  }
    first_trip = { "0" : { "mileage": 1000 } }
    
    empty_trips = {}
}

rule collect_trips {
    select when explicit trip_processed mileage re#(.*)# setting(m);
    pre {
      mileage = event:attr("mileage").klog("our passed in time: ")
      time = event:attr("time").klog("our passed in time: ")
    }
    always{
      ent:trips := ent:trips.defaultsTo(first_trip,"initialization was needed");
      ent:trips{[time, "mileage"]} := mileage
    }
}

rule collect_long_trips {
    select when explicit found_long_trip mileage re#(.*)# setting(m);
    pre {
      mileage = event:attr("mileage").klog("our passed in time: ")
      time = event:attr("time").klog("our passed in time: ")
    }
    fired {
      ent:long_trips := ent:long_trips.defaultsTo(first_trip,"initialization was needed");
      ent:long_trips{[time, "mileage"]} := mileage
    }
}

rule clear_trips {
select when car trip_reset
  always {
    ent:trips := empty_trips;
    ent:long_trips := empty_trips
  }
}

// ------------------- Added for Multiple Picos.  Gets the trips for the report ---------- //

  rule report_trips {
    select when fleet report_trips
    pre {
      the_trips = trips()
      attributes = {}
                    .put(["correlation_identifier"], event:attr("correlation_identifier"))
                    .put(["trips"], the_trips)
                    .klog("The attributes being sent back for the report: ")
      //parent_eci = event:attr("parent_eci").klog("Sending to: ");
      //parent_event_domain = event:attr("event_domain").klog("with this domain: ");
      //parent_event_identifier = event:attr("event_identifier").klog("And this id: ");
    }
    fired {
      raise vehicle event "recieve_report"
        with attributes = attributes
      //event:send({"cid":parent_eci}, "vehicle", "recieve_report")
      //with attrs = attributes;
    }
  }

}
