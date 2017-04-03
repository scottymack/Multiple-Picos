ruleset manage_fleet_new {
  meta {
    use module io.picolabs.pico alias wrangler
    shares sections, vehicles, __testing
  }
  global {
    sections = function() {
      ent:sections.defaultsTo({})
    }
 
    __testing = { "queries": [ { "name": "vehicles" },
                               { "name": "vehicles" } ],
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
 
    childFromID = function(name) {
      ent:sections{name}
    }
 
    nameFromID = function(name) {
      "Vehicle " + name
    }
  }
 
  rule collection_empty {
    select when collection empty
    always {
      ent:sections := {}
    }
  }
 
 
  rule section_already_exists {
    select when section needed
    pre {
      name = event:attr("name")
      exists = ent:sections >< name
    }
    if exists
    then
      send_directive("section_ready")
        with name = name
  }
 
  rule create_vehicle {
    select when car new_vehicle
    pre {
      name = event:attr("name")
      exists = ent:sections >< name
    }
    if not exists
    then
      noop()
    fired {
      raise pico event "new_child_request"
        attributes { "dname": nameFromID(name),
                     "color": "#FF69B4",
                     "name": name }
    }
  }
 
  rule pico_child_initialized {
    select when pico child_initialized
    pre {
      the_section = event:attr("new_child")
      name = event:attr("rs_attrs"){"name"}
    }
    if name.klog("found name")
    then
      event:send(
          { "eci": the_section.eci, "eid": 155,
            "domain": "pico", "type": "new_ruleset",
            "attrs": { "rid": "app_section", "name": name } } )
    fired {
      ent:sections := ent:sections.defaultsTo({});
      ent:sections{[name]} := the_section
    }
  }
 
  rule delete_vehicle {
    select when car unneeded_vehicle
    pre {
      name = event:attr("name")
      exists = ent:sections >< name
      eci = meta:eci
      child_to_delete = childFromID(name)
    }
    if exists then
      send_directive("section_deleted")
        with name = name
    fired {
      raise pico event "delete_child_request"
        attributes child_to_delete;
      ent:sections{[name]} := null
    }
  }
}
