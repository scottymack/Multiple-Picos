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
  
   get_trip = function(eci) {
       response = http:get("http://cs.kobj.net/sky/cloud/<rid>/<function>", {}.put(["_eci"], eci))
    }

   get_all_trips = function() {
    vehicles = vehicles();
    vehicle_trips = vehicles.map(function(x) {get_trip(x{["_eci"]})})
   }
  
  
cloud_url = "https://#{meta:host()}/sky/cloud/";
 
cloud = function(eci, mod, func, params) {
    //**** Change the address here *****
    response = http:get("http://cs.kobj.net/sky/cloud/<rid>/<function>", {})
    
    ("#{cloud_url}#{mod}/#{func}", (params || {}).put(["_eci"], eci));
 
 
    status = response{"status_code"};
 
 
    error_info = {
        "error": "sky cloud request was unsuccesful.",
        "httpStatus": {
            "code": status,
            "message": response{"status_line"}
        }
    };
 
 
    response_content = response{"content"}.decode();
    response_error = (response_content.typeof() eq "hash" && response_content{"error"}) => response_content{"error"} | 0;
    response_error_str = (response_content.typeof() eq "hash" && response_content{"error_str"}) => response_content{"error_str"} | 0;
    error = error_info.put({"skyCloudError": response_error, "skyCloudErrorMsg": response_error_str, "skyCloudReturnValue": response_content});
    is_bad_response = (response_content.isnull() || response_content eq "null" || response_error || response_error_str);
 
 
    // if HTTP status was OK & the response was not null and there were no errors...
    (status eq "200" && not is_bad_response) => response_content | error
 };
 
 all_trips = function () {
   vehicles = vehicles().klog("Vehicles: ");
   vehicle_trips = vehicles.all( function(x) {
        query_trip(x{["_eci"]}).klog("Vehicle Trips: ");
   });
   vehicle_trips;
 }
    
    
  trips = trips(){
    
  }
  
}


rule create_vehicle {
  select when car new_vehicle
    pre{
      name = event:attr("uid")
      parent_eci = " cj0xcd4p50001khqigd5c6o99"
      //random_name = "Vehicle_" + math:random(999);
      //name = event:attr("name").defaultsTo(random_name)
    }

// install the Subscriptions, trip_store, and modified track_trips
    event:send(
    { "eci": the_section.eci, "eid": "install-ruleset",
     "domain": "pico", "type": "new_ruleset",
     "attrs": { "rid": "app_section", "section_id": section_id } } )
    event:send(
    { "eci": the_section.eci, "eid": "install-ruleset",
     "domain": "pico", "type": "new_ruleset",
     "attrs": { "rid": "app_section", "section_id": section_id } } )

  fired {
    raise pico event "new_child_request"
      attributes { "Prototype_rids": "b507964x0.prod", "name": child_name, "parent_eci": parent_eci}
  }
}



rule delete_vehicle {
  select when car unneeded_vehicle 
    pre {
      name = event:attr("name")
    }
    fired {
      raise wrangler event "subscription_cancellation"
       with subscription_name = name
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
}
