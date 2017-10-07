defmodule GossipRegistry do
    use GenServer

    def start_link() do
        GenServer.start_link(__MODULE__, %{} , name: {:global, :registry})
    end

    def heard_rumour() do
        GenServer.cast({:global, :registry}, {:heardrumour})
    end

    def heard_enough() do
        GenServer.cast({:global, :registry}, {:heardenough})
    end

    def handle_cast({:heardrumour}, state) do
        count = Map.get(state, :heardcount)
        if(count==nil) do
            state = Map.put(state, :heardcount, 1)
        else
            state = Map.put(state, :heardcount, count + 1)
        end
        {:noreply, state}
    end

    def handle_cast({:heardenough}, state) do
        count = Map.get(state, :enoughcount)
        if(count==nil) do
            state = Map.put(state, :enoughcount, 1)
        else
            state = Map.put(state, :enoughcount, count + 1)
        end
        {:noreply, state}
    end
end