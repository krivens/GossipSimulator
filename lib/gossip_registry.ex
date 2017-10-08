defmodule GossipRegistry do
    use GenServer

    def start_link(args) do
        numnodes = Map.get(args, :numnodes)
        topology = Map.get(args, :topology)
        factor = case topology do
            "line" -> 15.0
            "2D" -> 0.9
            _ -> 0.75
        end
        percentage = :math.pow(0.95, factor * :math.log10(numnodes))
        #power = factor * :math.log10(numnodes)
        #IO.puts "Percentage was #{percentage} with power #{power}"
        uppercount = percentage * numnodes
        state = Map.put(args, :percentage, percentage)
        state = Map.put(state, :uppercount, uppercount)
        #IO.puts "Started the registry with #{numnodes} nodes"
        GenServer.start_link(__MODULE__, state , name: {:global, :registry})
    end

    def heard_rumour() do
        GenServer.cast({:global, :registry}, {:heardrumour})
    end

    def heard_enough() do
        GenServer.cast({:global, :registry}, {:heardenough})
    end

    def handle_cast({:heardrumour}, state) do
        count = Map.get(state, :heardcount)
        uppercount = Map.get(state, :uppercount)
        alreadyconverged = Map.get(state, :converged)
        newcount = if(count==nil) do
            1
        else
            count + 1
        end
        #IO.puts "Heard rumour #{newcount} out of #{numnodes} times"
        if( newcount >= uppercount && alreadyconverged == nil) do #ideally I should be looking for convergence in the orchestrator itself
            state = Map.put(state, :converged, true)
            GossipOrchestrator.converged({:gossip, newcount})            
        end
        state = Map.put(state, :heardcount, newcount)
        {:noreply, state}
    end

    def handle_cast({:heardenough}, state) do
        #numnodes = Map.get(state, :numnodes)
        count = Map.get(state, :enoughcount)
        if(count==nil) do
            state = Map.put(state, :enoughcount, 1)
        else
            newcount = count + 1
            state = Map.put(state, :enoughcount, newcount)
        end
        {:noreply, state}
    end
end