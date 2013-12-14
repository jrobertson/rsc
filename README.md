Introducing the RSC gem

## Example

    require 'rsc'

    # args: 1) RScript server address, 2) RScript package directory
    rsc = RSC.new 'rse','http://a0.jamesrobertson.eu/qbx/r/dandelion_a3'
    dev, state = 'light', 'on'
    rsc.homeauto.set_state dev, state


The above example sets a bedside light on by using the RSC gem which calls the package 'homeauto' with the method 'set_state' while supplying the arguments dev (device), and state (either on or off). The RSC gem creates the homeauto object dynamically by constructing the methods from the RScript file in dandelion_a3.

RScript file homeauto.rsf:

    &lt;package&gt;
      &lt;job id='set_state'&gt;
        &lt;script&gt;

          appliance, state = args
          reg = @services['registry']
          reg.set_key "hkey_apps/homeauto/#{appliance}/state", state
          
        &lt;/script&gt;
      &lt;/job&gt;    
      &lt;job id='fetch_state'&gt;
        &lt;script&gt;

          appliance = args.first
          reg = @services['registry']
          begin
            r = reg.get_key("hkey_apps/homeauto/#{appliance}/state").text.to_s
            String.new(r)
          rescue
            reg.set_key "hkey_apps/homeauto/#{appliance}/state", 'off'
            'new registry item set'
          end
          
        &lt;/script&gt;
      &lt;/job&gt;    
      
      &lt;job id='toggle_state'&gt;
        &lt;script&gt;

          require 'sps-pub'
          
          appliance = args.first
          reg = @services['registry']
          
          key = "hkey_apps/homeauto/#{appliance}/state"
          
          begin
          
            state = reg.get_key(key).text.to_s
            new_state = state == 'on' ? 'off' : 'on'
            reg.set_key key, new_state
            
            message = "aida: %s %s" % [appliance, new_state]
            puts 'message :' + message.inspect
            
            $ws.send message

            
            new_state
            
          rescue
          
            reg.set_key key, 'off'
            'new registry item set'
          end

        &lt;/script&gt;
      &lt;/job&gt;     
    &lt;/package&gt;

rsc gem rscriptclient
