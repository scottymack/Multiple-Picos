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
  users = vehicles(){
     vehicles = wrangler:subscriptions(null, "status", "subscribed");
     vehicles
  }
}


rule create_vehicle {
  select when car new_vehicle {
    pre{
      name = event:attr("uid")
      //random_name = "Vehicle_" + math:random(999);
      //name = event:attr("name").defaultsTo(random_name);
      attr = {}
            .put(["Prototype_rids"],"<child rid as a string>") // ; separated rulesets the child needs installed at creation
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
    pre{
      name = event:attr("name")
    }
  }
}

}
