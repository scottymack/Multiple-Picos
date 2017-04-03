ruleset manage_fleet_new {
  meta {
    use module io.picolabs.pico alias wrangler
    shares sections, vehicles, __testing, get_all_trips, get_trip
  }
  global {
    sections = function() {
      ent:sections.defaultsTo({})
    }
 
    __testing = { "queries": [ { "name": "vehicles" },
                               { "name": "get_all_trips" } ],
                  "events":  [ { "domain": "collection", "type": "empty" },
                               { "domain": "car", "type": "new_vehicle",
                                 "attrs": [ "name" ] },
                               { "domain": "car", "type": "unneeded_vehicle",
                                 "attrs": [ "name" ] }
                             ]
                }
 
    vehicles = function() {
      wrangler:children()
    }
 
    childFromID = function(section_id) {
      ent:sections{section_id}
    }
 
    nameFromID = function(section_id) {
      "Vehicle " + section_id
    }

    get_trip = function() {
       response = http:get("http://localhost:8080/sky/cloud/cj12gtqlr0025h0qib5dnjnzw/trip_store/trips");
       response_content = response{"content"}.decode()

    }

    get_all_trips = function() {
      vehicles = vehicles();
      vehicle_trips = vehicles.map(function(x) {
        get_trip(x{["eci"]})})
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
}
