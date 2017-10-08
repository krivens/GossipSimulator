defmodule Gossip do
  @moduledoc """
  A Gossip Simulator project. Given a number of nodes to use,
  this project simulates the Gossip or Push-sum protocol for the following network topologie:
  1. 2D - a non-wrapped mesh network
  2. imp2D - a non-wrapped mesh network with an extra random connection from each node to any other node in the network
  3. line - a line network
  4. full - a fully connected network
  """

  @doc """
  The entry point into the simulation.
  """
  def main (argv) do
    args = processargs (argv)
    GossipOrchestrator.start_link(args)
    GossipOrchestrator.startsimulation()
    receive do
      #do nothing, just wait
    end
  end

  defp processargs (argv) do
    argtuple = List.to_tuple(argv)
    noofargs = tuple_size argtuple
    if(noofargs != 3) do
      raiseinvalidarguments()
    end
    
    # the number of nodes
    {status, intval} = argtuple |> elem(0) |> testinteger
    if (status != true) do raiseinvalidarguments() end
    if (intval == 0 || intval == 1) do exit "Please enter a valid number of nodes" end

    # the topology
    topology = argtuple |> elem(1)
    unless (topology == "2D" or topology == "full" or topology == "imp2D" or topology == "line") do
      raiseinvalidarguments()
    end

    numnodes = (if(topology == "2D" or topology == "imp2D") do
                  intval |> :math.sqrt |> :math.ceil |> :math.pow(2) |> round
                else
                  intval
                end)

    # the algorithm
    algorithm = argtuple |> elem(2)
    unless (algorithm == "gossip" or algorithm == "push-sum") do
      raiseinvalidarguments()
    end

    # return a good set
    {numnodes, topology, algorithm}
  end

  defp raiseinvalidarguments() do
    exit "Usage: ./project2 numnodes<integer> topology<2D/full/imp2D/line> algorithm<gossip/push-sum>"
  end

  defp testinteger (stringval) do
    try do
      intval = stringval |> String.to_integer
      {true, intval}
    rescue 
      _ -> {false, 0}
    end
  end
end
