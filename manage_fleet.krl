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
