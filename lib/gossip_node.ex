defmodule GossipNode do
    use GenServer
    @moduledoc """
    Each node in the network. The node stores a list of its neighbours.
    Its initial state is a tuple containing its row and column number.
    Messages that come in can 
    1. Tell it its neighbours -> Update neighbours list
    2. Tell it a rumour with a round number -> Tell the orchestrator it's heard a rumour
            , start sending to one of its neighbours randomly until it's heard the rumour 10 times
            , when upper count is reached tell data collector it's done
    """

    @doc """
    """
    def start_link(args) do
        GenServer.start_link(__MODULE__, args)
    end

    def add_neighbours(pid, neighbours) do
        GenServer.cast(pid, {:addneighbours, neighbours})    
    end

    def hear_rumour(pid, roundnumber) do
        GenServer.cast(pid, {:hearrumour, roundnumber})
    end

    def push_sum(pid, svalue, wvalue, roundnumber) do
        GenServer.cast(pid, {:pushsum, svalue, wvalue, roundnumber})
    end

    def get_state(pid) do
        GenServer.call(pid, {:getstate})
    end

    def handle_cast({:addneighbours, neighbours}, state) do
        newstate = Map.put(state, :neighbours, neighbours)
        {:noreply, newstate}
    end

    def handle_cast({:hearrumour, roundnumber}, state) do
        count = Map.get(state, :rumourcount)
        newstate = if(count == nil) do
                    spawn(sendrumour(self(), roundnumber))
                    #TODO register that you heard the rumour
                    Map.put(state, :rumourcount, 1)
                else
                    #TODO register that you've heard the rumour more than 10 times
                    Map.put(state, :rumourcount, count + 1) 
        end
        {:noreply, newstate}
    end

    def handle_cast({:pushsum, svalue, wvalue, roundnumber}, state) do
        neighbours = Map.get(state, :neighbours)
        neighbour = getrandomneighbour(neighbours)
        s = Map.get(state, :s)
        w = Map.get(state, :w)
        news = (s + svalue)/2 # the new value of s
        neww = (w + wvalue)/2 # the new value of w
        if (((news/neww) - (s/w) |> abs) > 0.0000000001) do # if the ratio has changed by more than 1 in 10^-10 reset
            pushcount = 0
        else
            pushcount = Map.get(state, :pushcount)
        end
        GossipNode.push_sum(neighbour, news, neww, roundnumber)
        {:noreply, state}
    end

    def handle_call({:getstate}, _from, state) do
        {:reply, state, state}
    end

    defp sendrumour(pid, roundnumber) do
        state = GossipNode.get_state(pid)
        neighbours = Map.get(state, :neighbours)
        count = Map.get(state, :rumourcount)
        if(count != nil && count <= 10) do
            neighbourpid = getrandomneighbour(neighbours)
            GossipNode.hear_rumour(neighbourpid, roundnumber + 1)
            Process.sleep(5) # make the process sleep for 5ms
            sendrumour(pid, roundnumber + 1)
        end
    end

    defp getrandomneighbour(neighbours) do
        case neighbours do
            :completenetwork -> self() # TODO get a service neighbour
            _ -> elem(neighbours, :rand.uniform(tuple_size(neighbours)) - 1)
        end
    end
end