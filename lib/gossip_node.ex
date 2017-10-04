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
    def start_link(__MODULE__, args, opts) do
        
    end

    def add_neighbour(neighbourdata, state) do
        handle_cast({:addneighbour, neighbourdata}, state)    
    end

    def handle_cast({:addneighbour, neighbourdata}, state) do
        neighbourmapnew = Map.update(state.neighbourmap, neighbourdata.neighbournumber, neighbourdata.neighbourname)
        Map.update(state, :neighbours, neighbourmapnew)
        {:noreply, state}
    end

    def handle_cast({:rumour, round}, state) do
        
    end

    def handle_cast({:failnode}, state) do
        
    end

    def handle_cast({:failconnection, neighour, mode}, state) do
        
    end
end