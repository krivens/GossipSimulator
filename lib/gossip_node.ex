defmodule GossipNode do
    use GenServer
    @moduledoc """
    Each node in the network. The node stores a list of its neighbours.
    Its initial state is a tuple containing its row and column number. Round is also set to 0.
    Messages that come in can 
    1. Tell it its neighbours -> Update neighbours list
    2. Tell it a rumour with a round number -> Tell the orchestrator it's heard a rumour
            , start sending to one of its neighbours randomly until an upper count is reached
            , when upper count is reached tell supervisor it's done
    3. Tell it to die
    4. Tell it to ignore a connection to its neighbour temporarily or permanently
    """

    @doc """
    """
    def start_link(args) do
        GenServer.start_link(__MODULE__, args)
    end

    def add_neighbours(pid, neighbours) do
        GenServer.cast(pid, {:addneighbours, neighbours})    
    end

    def hear_rumour(pid) do
        GenServer.cast(pid, {:hearrumour})
    end

    def get_state(pid) do
        GenServer.call(pid, {:getstate})
    end

    def handle_cast({:addneighbours, neighbours}, state) do
        newstate = Map.put(state, :neighbours, neighbours)
        {:noreply, newstate}
    end

    def handle_cast({:hearrumour}, state) do
        count = Map.get(state, :rumourcount)
        newstate = if(count == nil) do
                    spawn(sendrumour(self()))
                    #TODO register that you heard the rumour
                    Map.put(state, :rumourcount, 1)
                else
                    #TODO register that you've heard the rumour more than 10 times
                    Map.put(state, :rumourcount, count + 1) 
        end
        {:noreply, newstate}
    end

    def handle_call({:getstate}, _from, state) do
        {:reply, state}
    end

    defp sendrumour(pid) do
        state = GossipNode.get_state(pid)
        neighbours = Map.get(state, :neighbours)
        count = Map.get(state, :rumourcount)
        if(count != nil && count <= 10) do
            getrandomneighbour(neighbours)
        end
    end

    defp getrandomneighbour(neighbours) do
        case neighbours do
            :completenetwork -> self() # TODO get a service neighbour
            _ -> elem(neighbours, :rand.uniform(tuple_size(neighbours)) - 1)
        end
    end
end