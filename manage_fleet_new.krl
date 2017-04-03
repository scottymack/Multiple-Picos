ruleset manage_fleet_new {
  meta {
    use module io.picolabs.pico alias wrangler
    shares sections, showChildren, __testing
  }
  global {
    sections = function() {
      ent:sections.defaultsTo({})
    }
 
    __testing = { "queries": [ { "name": "vehicles" },
                               { "name": "vehicles" } ],
                  "events":  [ { "domain": "collection", "type": "empty" },
                               { "domain": "car", "type": "new_vehicle",
                                 "attrs": [ "section_id" ] },
                               { "domain": "car", "type": "unneeded_vehicle",
                                 "attrs": [ "section_id" ] }
                             ]
                }
 
    vehicles = function() {
      wrangler:children()
    }
 
    childFromID = function(section_id) {
      ent:sections{section_id}
    }
 
    nameFromID = function(section_id) {
      "Section " + section_id + " Pico"
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
      section_id = event:attr("section_id")
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
      section_id = event:attr("section_id")
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
            "attrs": { "rid": "app_section", "section_id": section_id } } )
    fired {
      ent:sections := ent:sections.defaultsTo({});
      ent:sections{[section_id]} := the_section
    }
  }
 
  rule delete_vehicle {
    select when car unneeded_vehicle
    pre {
      section_id = event:attr("section_id")
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
