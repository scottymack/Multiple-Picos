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
  vehicles = vehicles(){
     vehicles = wrangler:subscriptions(null, "status", "subscribed");
     vehicles
  }
  
cloud_url = "https://#{meta:host()}/sky/cloud/";
 
cloud = function(eci, mod, func, params) {
    response = http:get("#{cloud_url}#{mod}/#{func}", (params || {}).put(["_eci"], eci));
 
 
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
  fired {
    raise pico event "new_child_request"
      attributes { "Prototype_rids": "b507964x0.prod", "name": child_name, "parent_eci": parent_eci}
  }
}


rule delete_vehicle {
  select when car unneeded_vehicle {
    pre {
      name = event:attr("name");
    }
    if(not name.isnull()) then {
      wrangler:deleteChild(name)
    }
    fired {
      log "Deleted child named " + name;
    } else {
      log "No child named " + name;
    }
  }
}

rule generate_report {
  select when fleet generate_report
  pre {
          correlation_identifier = "Report_" + math:random(999);
          //the_ecis = vehicle_ecis();
          attrs = {}
              .put(["correlation_identifier"], correlation_identifier)
            //.put(["vehicle_ecis"], the_ecis)
              .klog("Attributes sent to Track Trips: ");
      }
      fired {
        raise explicit event 'start_scatter_report' attributes attrs;
      }
    }

}
