defmodule ElixirFBPNetworkTest do

  use ExUnit.Case, async: false

  alias ElixirFBP.Graph
  alias ElixirFBP.Network

  import ExUnit.CaptureLog

  @graph_1      "graph_1"
  @node_1       "node_1"
  @node_2       "node_2"

  test "Start and stop the FBP Network" do
    Network.start_link
    assert :ok == Network.stop
  end

  test "Create an ElixirFBP Graph" do
    Network.start_link
    {:ok, _fbp_graph = Network.clear(@graph_1)}
    status = Network.get_status(@graph_1)
    assert status == {false, false}
    # Make sure the graph and network are stopped
    Network.stop(@graph_1)
    assert :ok == Network.stop
  end

  test "Create and start an ElxirFBP Graph with defaults (push mode)" do
    Network.start_link
    {:ok, fbp_graph} = Network.clear(@graph_1)
    Graph.add_node(fbp_graph, @node_1, "Math.Add")
    Graph.add_node(fbp_graph, @node_2, "Core.Log")
    _edge = Graph.add_edge(
                  fbp_graph,
                  @node_1, :sum,
                  @node_2, :in_port)

    Graph.add_initial(fbp_graph, 42, @node_1, :addend)
    Graph.add_initial(fbp_graph, 24, @node_1, :augend)
    assert capture_log(fn ->
      Network.start(@graph_1)
      # Need a slight delay to allow for the log message to shou up
      :timer.sleep(5)
    end) =~ "66"
    {true, true} = Network.get_status(@graph_1)
    # Make sure the graph and network are stopped
    Network.stop(@graph_1)
  end

  test "Create and start an ElxirFBP Graph in push mode" do
    Network.start_link
    {:ok, fbp_graph} = Network.clear(@graph_1)
    Graph.add_node(fbp_graph, @node_1, "Math.Add")
    Graph.add_node(fbp_graph, @node_2, "Core.Log")
    _edge = Graph.add_edge(
                  fbp_graph,
                  @node_1, :sum,
                  @node_2, :in_port)

    Graph.add_initial(fbp_graph, 53, @node_1, :addend)
    Graph.add_initial(fbp_graph, 35, @node_1, :augend)
    assert capture_log(fn ->
      Network.start(@graph_1, :push)
      # Need a slight delay to allow for the log message to shou up
      :timer.sleep(5)
    end) =~ "88"
    {true, true} = Network.get_status(@graph_1)
    # Make sure the graph and network are stopped
    Network.stop(@graph_1)
  end

  test "Create and start an ElxirFBP Graph in pull mode" do
    Network.start_link
    {:ok, fbp_graph} = Network.clear(@graph_1)
    Graph.add_node(fbp_graph, @node_1, "Math.Add")
    Graph.add_node(fbp_graph, @node_2, "Core.Log")
    _edge = Graph.add_edge(
                  fbp_graph,
                  @node_1, :sum,
                  @node_2, :in_port)

    Graph.add_initial(fbp_graph, 32, @node_1, :addend)
    Graph.add_initial(fbp_graph, 23, @node_1, :augend)
    assert capture_log(fn ->
      Network.start(@graph_1, :pull)
      # Need a slight delay to allow for the log message to shou up
      :timer.sleep(5)
    end) =~ "55"
    {true, true} = Network.get_status(@graph_1)
    # Make sure the graph and network are stopped
    Network.stop(@graph_1)
  end

end
