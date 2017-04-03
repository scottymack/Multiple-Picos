ruleset manage_fleet {
  meta {
    name "Manage Fleet"
    description <<
    A first ruleset for the Quickstart>>
    author "Scott McKenzie"
    use module io.picolabs.pico alias wrangler
    use module Subscriptions
    logging on
    shares __testing
  }

  global {
  vehicles = function(){
     vehicles = wrangler:children();
     vehicles
  }
    
  __testing = { "events":  [ { "domain": "car", "type": "new_vehicle"}, { "domain": "car", "type": "unneeded_vehicle", "attrs": [ "name" ] } ] }


    get_trip = function(eci) {
       response = http:get("http://cs.kobj.net/sky/cloud/<rid>/<function>", {}.put(["_eci"], eci))
    }

    get_all_trips = function() {
    vehicles = vehicles();
    vehicle_trips = vehicles.map(function(x) {get_trip(x{["_eci"]})})
    }
}

rule create_vehicle {
  select when car new_vehicle
    pre{
      //name = event:attr("uid")
      parent_eci = " cj0xcd4p50001khqigd5c6o99"
      child_name = "Vehicle_" + 1
      name = event:attr("name").defaultsTo(random_name)
    }

// install the Subscriptions, trip_store, and modified track_trips
//    event:send(
//    { "eci": the_section.eci, "eid": "install-ruleset",
//     "domain": "pico", "type": "new_ruleset",
//     "attrs": { "rid": "app_section", "section_id": section_id } } )
//    event:send(
//    { "eci": the_section.eci, "eid": "install-ruleset",
//     "domain": "pico", "type": "new_ruleset",
//     "attrs": { "rid": "app_section", "section_id": section_id } } )

  fired {
    raise pico event "new_child_request"
      attributes { "dname": child_name, "color": "#FF69B4"}
  }
}

rule delete_vehicle {
  select when car unneeded_vehicle 
    pre {
      name = event:attr("name")
      eci = meta:eci
    }
    send_directive("Deleted Vehicle") with
        something = name
    fired {
    raise pico event "delete_child_request"
      attributes name
    }
}

rule generate_report {
  select when fleet generate_report
  pre {
          correlation_identifier = "Report_" + math:random(999)
          vehicles = vehicles()
          //the_ecis = vehicle_ecis();
          attrs = {}
              .put(["correlation_identifier"], correlation_identifier)
              .put(["vehicles"], vehicles)
              .klog("Attributes sent to Track Trips: ")
      }
      fired {
        raise explicit event "start_scatter_report" attributes attrs
      }
    }


rule for_each_vehicle {
select when start_scatter_report
  foreach event:attr("vehicles") setting (x)
}

rule receive_report {
  select when vehicle recieve_report
  //store the results in a fleet trip report
  fired {
    ent:fleetReport.append([response])
  }
}


}
