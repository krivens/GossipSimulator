defmodule GossipOrchestrator do

    def startgossipsimulation(args) do
        createnetwork(elem(args, 0), elem(args,1))        
    end

    def createnetwork(numnodes, topology) do
        # no. of columns in the network matrix
        columns = if (topology == "2D" or topology == "imp2D") do
                numnodes |> :math.sqrt |> round
            else
                1
            end

        # first, create an actor for each node and put it in a list
        # empty node list to begin
        nodelist = []
        for nodeindex <- 0..numnodes do
            noderow = div(nodeindex, columns)
            nodecol = rem(nodeindex, columns)
            IO.puts "Node #{nodeindex} created with row #{noderow} and col #{nodecol}"
            nodelist = nodelist ++ [{noderow, nodecol}] # TODO: to put in the PID here
        end
        
        # convert the list to a tuple so that you can have constant-time access
        nodes = List.to_tuple(nodelist)

        # tell each node who its neighbours are
        neighbourize(nodes, topology, numnodes, columns)
    end

    defp neighbourize(nodes, topology, numnodes, columns) do
        for nodeindex <- 0..numnodes do
            if(topology == "full") do
                
            end
        end 
    end
end