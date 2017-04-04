ruleset manage_fleet_new {
  meta {
    use module io.picolabs.pico alias wrangler
    shares sections, vehicles, __testing, get_all_trips, get_trip
  }
  global {
    vehicles = function() {
      ent:sections.defaultsTo({})
    }
 
    __testing = { "queries": [ { "name": "vehicles" },
                               { "name": "get_all_trips" } ],
                  "events":  [ { "domain": "collection", "type": "empty" },
                               { "domain": "car", "type": "new_vehicle",
                                 "attrs": [ "name" ] },
                               { "domain": "car", "type": "unneeded_vehicle",
                                 "attrs": [ "name" ] },
                               { "domain": "fleet", "type": "start_report"}
                             ]
                }
 
   getLastFive = function() {
     length = ent:fleetReport.keys().length();
     (length > 5) => ent:fleetReport.values().slice(length - 5, length - 1) | ent:fleetReport.values()

   }

    children = function() {
      wrangler:children()
    }

    full_report = function() {
      ent:fleetReport.defaultsTo([])
    }
 
    childFromID = function(section_id) {
      ent:sections{section_id}
    }
 
    nameFromID = function(section_id) {
      "Vehicle " + section_id
    }

    get_trip = function(len, eci) {
       report_response = {};
       myLength = len;
       response = http:get("http://localhost:8080/sky/cloud/" + eci + "/trip_store/trips");
       response_content = response{"content"}.decode();
       report_response = {"vehicles": myLength, "responding": myLength, "trips": response_content}
    }

    get_all_trips = function() {
      vehicles = vehicles();
      vehicle_trips = vehicles.map(function(x) {get_trip(vehicles.length(), x["eci"])})
    }
  }
 
  rule collection_empty {
    select when collection empty
    always {
      ent:sections := {}
    }
  }
 
 
  rule section_already_exists {
    select when car new_vehicle
    pre {
      section_id = event:attr("name")
      exists = ent:sections >< section_id
    }
    if exists
    then
      send_directive("section_ready")
        with section_id = section_id
  }
 
  rule create_vehicle {
    select when car new_vehicle
    pre {
      section_id = event:attr("name")
      exists = ent:sections >< section_id
    }
    if not exists
    then
      noop()
    fired {
      raise pico event "new_child_request"
        attributes { "dname": nameFromID(section_id),
                     "color": "#FF69B4",
                     "section_id": section_id }
    }
  }
 
  rule pico_child_initialized {
    select when pico child_initialized
    pre {
      the_section = event:attr("new_child")
      section_id = event:attr("rs_attrs"){"section_id"}
    }
    if section_id.klog("found section_id")
    then
      event:send(
          { "eci": the_section.eci, "eid": 155,
            "domain": "pico", "type": "new_ruleset",
            "attrs": { "rid": "Subscriptions", "section_id": section_id } } )
      event:send(
          { "eci": the_section.eci, "eid": 155,
            "domain": "pico", "type": "new_ruleset",
            "attrs": { "rid": "trip_store", "section_id": section_id } } )
      event:send(
          { "eci": the_section.eci, "eid": 155,
            "domain": "pico", "type": "new_ruleset",
            "attrs": { "rid": "track_trips", "section_id": section_id } } )
    fired {
      ent:sections := ent:sections.defaultsTo({});
      the_section.put(["section_id"], section_id);
      ent:sections{[section_id]} := the_section
    }
  }
 
  rule delete_vehicle {
    select when car unneeded_vehicle
    pre {
      section_id = event:attr("name")
      exists = ent:sections >< section_id
      eci = meta:eci
      child_to_delete = childFromID(section_id)
    }
    if exists then
      send_directive("section_deleted")
        with section_id = section_id
    fired {
      raise pico event "delete_child_request"
        attributes child_to_delete;
      ent:sections{[section_id]} := null
    }
  }


rule generate_report {
  select when fleet generate_report
  foreach vehicles() setting (x)
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


rule start_report {
   select when fleet start_report
  always {
    ent:fleetReport := ent:fleetReport.defaultsTo({});
    raise fleet event "get_report"
  }
}

rule get_report {
   select when fleet get_report
      foreach vehicles() setting (v)
      pre {
        eci = v["eci"]
        attrs = {"eci": eci, "reportID": ent:fleetReport.length(), "vehicleID" : v["id"]}
      }
      event:send({
      "eci": v["eci"],
      "eid": "WHATEVER",
      "domain": "explicit",
      "type": "generate_report",
      "attrs": attrs
      })
}

rule receive_report {
  select when explicit receive_report
  pre {
    response = event:attrs("trips").klog("THE TRIPS I GOT BACK" + event:attrs("trips"))
    reportID = ent:fleetReport.length()
  }
  fired {
    ent:fleetReport{[reportID]} := ent:fleetReport[reportID].defaultsTo({}); 
    ent:fleetReport{[reportID, "vehicles"]} := vehicles().length();
    ent:fleetReport{[reportID, "responding"]} := [reportID, "responding"] + 1;
    ent:fleetReport{[reportID, vehicleID]} := response
  }
 }
}
