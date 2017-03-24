ruleset manage_fleet {
  meta {
    name "Manage Fleet"
    description <<
    A first ruleset for the Quickstart>>
    author "Scott McKenzie"
    logging on
    shares hello, __testing
  }
  
  global {
  users = vehicles(){
  
  }
}


rule create_vehicle {
  select when car new_vehicle {
    pre{
      child_name = event:attr("name");
      attr = {}
            .put(["Prototype_rids"],"<child rid as a string>") // ; separated rulesets the child needs installed at creation
            .put(["name"],child_name) // name for child_name
            .put(["parent_eci"],parent_eci) // eci for child to subscribe
            ;
    }
    always{
      raise wrangler event "child_creation"
      attributes attr.klog("attributes: ");
      log("create child for " + child);
    }
  }
}




rule delete_vehicle {
  select when car unneeded_vehicle {
  }
}

}
