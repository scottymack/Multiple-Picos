ruleset manage_fleet {
  meta {
    name "Manage Fleet"
    description <<
    A first ruleset for the Quickstart>>
    author "Scott McKenzie"
    use module v1_wrangler alias wrangler
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
  select when car new_vehicle {
    pre{
      name = event:attr("uid")
      parent_eci = "E1A5DE98-10C1-11E7-A4F9-5CB2E71C24E1"
      //random_name = "Vehicle_" + math:random(999);
      //name = event:attr("name").defaultsTo(random_name);
      attr = {}
            .put(["Prototype_rids"],"b507964x0.prod") // ; separated rulesets the child needs installed at creation
            .put(["name"],child_name) // name for child_name
            .put(["parent_eci"],parent_eci) // eci for child to subscribe
            ;
    }
    {
      wrangler:createChild(name);
    }
    always{
      log("create child names " + name);
    }
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

}
