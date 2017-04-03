ruleset track_trips {
  meta {
    name "Track Trips Part 2"
    description <<
A first ruleset for single pico part 2
>>
    author "Scott McKenzie"
    logging on
    shares __testing
  }

global {
  __testing = { "events": [{ "domain": "car", "type": "new_trip",
                              "attrs": [ "mileage" ] } ] }
                              
  long_trip = 100
}
 
rule process_trip {
  select when car new_trip mileage re#(.*)# setting(m);
  send_directive("trip") with
    trip_length = m
    
    always {
      raise explicit event "trip_processed"
    attributes { "attributes": event:attrs(), "time" : time:now(), "mileage" : m}
    }
}


rule find_long_trips {
  select when explicit trip_processed mileage re#(.*)# setting(m);
    pre {
      time = event:attr("time").klog("our passed in time: ")
    }
  if m.as("Number") < long_trip then
      send_directive("trip") with
      status = "This is not a long trip"
  fired {
  } 
  else {
   raise explicit event "found_long_trip"
   attributes { "attributes": event:attrs(), "time" : time, "mileage" : m}
  }
}
}
