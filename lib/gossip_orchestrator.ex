defmodule GossipOrchestrator do
    use GenServer

    def start_link(args) do
        GenServer.start_link(__MODULE__, %{:numnodes => elem(args,0), :topology => elem(args, 1), :algorithm => elem(args, 2)}, name: {:global, :orchestrator})
    end

    def startsimulation do
        GenServer.call({:global, :orchestrator}, {:createnetwork}, 600000)
        #IO.puts "Finished creating the network"
        GenServer.call({:global, :orchestrator}, {:doalgorithm})
        #IO.puts "Finished starting off the algorithm"
    end

    def converged(args) do
        GenServer.cast({:global, :orchestrator}, {:converged, args})
    end

    def get_random_neighbour_full do
        GenServer.call({:global, :orchestrator}, {:getrandomneighbourfull})
    end

    def handle_call({:createnetwork}, _from, state) do
        numnodes = Map.get(state, :numnodes)
        topology = Map.get(state, :topology)
        nodes = createnetwork(numnodes, topology)
        {:reply, nodes, Map.put(state, :nodes, nodes)}
    end

    def handle_call({:doalgorithm}, _from, state) do
        nodes = Map.get(state, :nodes)
        algorithm = Map.get(state, :algorithm)
        topology = Map.get(state, :topology)
        numnodes = Map.get(state, :numnodes)
        #IO.puts "Starting the algorithm"
        case algorithm do
            "gossip" -> 
                GossipRegistry.start_link(%{:numnodes => numnodes, :topology => topology})
                starttime = System.monotonic_time(:microsecond)
                state = Map.put(state, :starttime, starttime)                
                GossipNode.hear_rumour(elem(nodes, :rand.uniform(tuple_size(nodes) - 1)), 0)
            "push-sum" -> 
                starttime = System.monotonic_time(:microsecond)
                state = Map.put(state, :starttime, starttime)               
                GossipNode.push_sum(elem(nodes, :rand.uniform(tuple_size(nodes) - 1)), 0, 0, 0)
        end
        {:reply, :started, state}
    end

    def handle_call({:getrandomneighbourfull}, _from, state) do
        nodes = Map.get(state, :nodes)
        numnodes = tuple_size(nodes)
        {:reply, elem(nodes, :rand.uniform(numnodes - 1)), state}
    end

    def handle_cast({:converged, args}, state) do
        endtime = System.monotonic_time(:microsecond)
        starttime = Map.get(state, :starttime)
        totaltime = endtime - starttime
        numnodes = Map.get(state, :numnodes)
        topology = Map.get(state, :topology)
        algorithm = Map.get(state, :algorithm)
        case args do
        {:gossip, reachednodes} ->
            IO.puts "Time taken for #{reachednodes} out of #{numnodes} nodes in #{topology} topology on #{algorithm} algorithm was #{totaltime} us"
        _ ->
            IO.puts "Time taken for #{numnodes} nodes in #{topology} topology on #{algorithm} algorithm was #{totaltime} us with s/w #{args}"
        end
        :init.stop()
        {:noreply, state}
    end

    defp createnetwork(numnodes, topology) do
        # no. of columns in the network matrix
        rows = if (topology == "2D" or topology == "imp2D") do
                numnodes |> :math.sqrt |> round
            else
                1
            end
        
        columns = if (topology == "2D" or topology == "imp2D") do
                rows
            else
                numnodes
            end

        # first, create an actor for each node and put it in a list
        # empty node list to begin
        nodelist = createnodes([],numnodes, columns, 0)
        
        # convert the list to a tuple so that you can have constant-time access
        nodes = List.to_tuple(nodelist)

        # tell each node who its neighbours are
        neighbourize(nodes, topology, numnodes, rows, columns)
        nodes
    end

    defp createnodes(nodelist, numnodes, columns, nodeindex) do
        case numnodes do
            ^nodeindex -> nodelist
            _ ->
                noderow = div(nodeindex, columns)
                nodecol = rem(nodeindex, columns)
                {:ok, nodepid} = GossipNode.start_link(%{:identity => {nodeindex, noderow, nodecol}, :s => (nodeindex + 1), :w => 1}) 
                createnodes(nodelist ++ [nodepid], numnodes, columns, nodeindex + 1)
        end
    end

    defp neighbourize(nodes, topology, numnodes, rows, columns) do
        case topology do
        "full" -> 
            for nodeindex <- 0..(numnodes-1) do
                nodepid = elem(nodes, nodeindex)
                GossipNode.add_neighbours(nodepid, :completenetwork)
            end
        "2D" ->
            for nodeindex <- 0..(numnodes-1) do
                nodepid = elem(nodes, nodeindex)
                neighbourlist = getadjacentneighbours(nodes, nodeindex, rows, columns)
                neighbours = List.to_tuple(neighbourlist)
                GossipNode.add_neighbours(nodepid, neighbours)
            end
        "imp2D" ->
            for nodeindex <- 0..(numnodes-1) do
                nodepid = elem(nodes, nodeindex)
                neighbourlist = getadjacentneighbours(nodes, nodeindex, rows, columns)
                neighbourlist = neighbourlist ++ [elem(nodes, (:rand.uniform(numnodes) - 1))]
                neighbours = List.to_tuple(neighbourlist)
                GossipNode.add_neighbours(nodepid, neighbours)
            end
        "line" ->
            for nodeindex <- 0..(numnodes-1) do
                nodepid = elem(nodes, nodeindex)
                neighbourlist = getadjacentneighbours(nodes, nodeindex, rows, columns)
                neighbours = List.to_tuple(neighbourlist)
                GossipNode.add_neighbours(nodepid, neighbours)
            end 
        end
    end

    defp getadjacentneighbours(nodes, nodeindex, rows, columns) do
        neigbourlist = []
        if (div(nodeindex, columns) != 0) do # for all except first row
            aboveneigbourindex = nodeindex - columns # 1 row up
            neigbourlist = neigbourlist ++ [elem(nodes, aboveneigbourindex)]
        end
        if(div(nodeindex, columns) != (rows-1)) do # for all except last row
            belowneigbourindex = nodeindex + columns # 1 row down
            neigbourlist = neigbourlist ++ [elem(nodes, belowneigbourindex)]
        end
        if(rem(nodeindex, columns) != 0) do # for all except first column
            leftneigbourindex = nodeindex - 1 # 1 element left
            neigbourlist = neigbourlist ++ [elem(nodes, leftneigbourindex)]
        end
        if(rem(nodeindex, columns) != (columns-1)) do # for all except last column
            rightneigbourindex = nodeindex + 1 # 1 element right
            neigbourlist = neigbourlist ++ [elem(nodes, rightneigbourindex)]
        end
        neigbourlist
    end

end