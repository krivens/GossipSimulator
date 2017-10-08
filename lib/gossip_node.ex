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
        GenServer.cast(pid, {:hearrumour, pid, roundnumber})
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

    def handle_cast({:hearrumour, pid, roundnumber}, state) do
        #pidstring = inspect(pid)
        #IO.puts "Heard rumour at process #{pidstring}"
        count = Map.get(state, :rumourcount)
        newstate = if(count == nil) do
                    spawn(__MODULE__, :sendrumour, [pid, roundnumber])
                    GossipRegistry.heard_rumour
                    Map.put(state, :rumourcount, 1)
                else
                    GossipRegistry.heard_enough
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
        pushcount =  if (((news/neww) - (s/w) |> abs) > 0.0000000001) do # if the ratio has changed by more than 1 in 10^-10 reset
                        0
                    else
                        test = Map.get(state, :pushcount)
                        if (test == nil) do
                            0
                        else
                            test + 1
                        end
                    end
        state = Map.put(state, :s, news)
        state = Map.put(state, :w, neww)
        state = Map.put(state, :pushcount, pushcount)
        #ratio = news/neww
        #IO.puts "Got a pushcount at " <> inspect(pid) <> " with s/w #{ratio} and pushcount #{pushcount}"
        unless (pushcount == 3) do
            GossipNode.push_sum(neighbour, news, neww, roundnumber + 1)        
        else
            GossipOrchestrator.converged(news/neww)
        end
        {:noreply, state}
    end

    def handle_call({:getstate}, _from, state) do
        {:reply, state, state}
    end

    def sendrumour(pid, roundnumber) do
        state = GossipNode.get_state(pid)
        neighbours = Map.get(state, :neighbours)
        count = Map.get(state, :rumourcount)
        if(count != nil && count <= 10) do
            neighbourpid = getrandomneighbour(neighbours)
            GossipNode.hear_rumour(neighbourpid, roundnumber + 1)
            #Process.sleep(5) # make the process sleep for 5ms
            sendrumour(pid, roundnumber + 1)
        end
    end

    defp getrandomneighbour(neighbours) do
        case neighbours do
            :completenetwork -> GossipOrchestrator.get_random_neighbour_full
            _ -> elem(neighbours, :rand.uniform(tuple_size(neighbours)) - 1)
        end
    end

end