defmodule GossipOrchestrator do

    def startgossipsimulation(args) do
        createnetwork(elem(args, 0), elem(args,1))        
    end

    def createnetwork(numnodes, topology) do
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
    end

    defp createnodes(nodelist, numnodes, columns, nodeindex) do
        case numnodes do
            ^nodeindex -> nodelist
            _ ->
                noderow = div(nodeindex, columns)
                nodecol = rem(nodeindex, columns)
                {:ok, nodepid} = GossipNode.start_link(%{:identity => {nodeindex, noderow, nodecol}}) 
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