ruleset trip_store {
  meta {
    name "Track Trips"
    description <<A first ruleset for single pico part 3>>
    author "Scott McKenzie"
    logging on
    shares trips, long_trips, short_trips, __testing
    provides long_trips, short_trips
  }
  
global {
    __testing = { "queries": [ { "name": "trips" }],
                  "events":  [{ "domain": "vehicle", "type": "get_report"}]}
  
  trips = function(){
      ent:trips.defaultsTo({})
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

rule get_report {
  select when explicit generate_report
  pre {
    the_trips = trips()
    vehicleID = event:attr("vehicleID")
    reportID = event:attr("reportID")
  }
  event:send({
    "eci": "cj0xcd4p50001khqigd5c6o99",
    "eid": "WHATEVER",
    "domain": "explicit",
    "type": "receive_report",
    "attrs": {"trips": trips(), "vehicleID" : vehicleID, "reportID": reportID}
    }.klog("REPORT TO SEND BACK " + trips()))
}

}
