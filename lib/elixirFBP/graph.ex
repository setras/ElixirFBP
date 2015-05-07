defmodule ElixirFBP.Graph do
  @moduledoc """
  ElxirFBP.Graph is a GenServer that provides support for the creation and
  maintainance of an FBP Graph.

  An FBP graph contains Nodes connected by Edges. Facilities are provided for
  the creation, deletion, and modification of nodes and edges. Initial Information
  Packets (IIP's) can also be specified.

  Graphs are implemented using Erlang's digraph library.

  Functions supported by this module are based on NoFlo's FBP Network Protocol,
  specifically the graph sub-protocol. See http://noflojs.org/documentation/protocol/
  for the details.

  TODO: Provide support for Port and Group maintenance.

  """
  defstruct [
    id: nil,
    name: "",
    library: nil,
    main: false,
    description: "",
    digraph: nil
  ]
  @type t :: %ElixirFBP.Graph{id: String.t, name: String.t}
  use GenServer

  ########################################################################
  # The External API
  @doc """
  Starts things off with the creation of the state.
  """
  def start_link(id \\ nil, name \\ "", library \\ nil,
                 main \\ false, description \\ "") do
    digraph = :digraph.new()
    fbp_graph = %ElixirFBP.Graph{id: id, name: name, library: library,
          main: main, description: description, digraph: digraph}
    GenServer.start_link(__MODULE__, fbp_graph, name: __MODULE__)
  end

  @doc """
  Retreive the digraph from the FBP Graph - primarily for testing/debugging
  """
  def get_graph do
    GenServer.call(__MODULE__, :get_graph)
  end

  @doc """
  Clear/empty the current FBP Graph.
  """
  def clear do
    GenServer.call(__MODULE__, :clear)
  end

  @doc """
  Add a node to the FBP Graph
  """
  def add_node(pid, node) do
    GenServer.call(pid, {:add_node, node})
  end

  ########################################################################
  # The GenServer implementation
  @doc """
  Return the digraph in this FBP Graph
  """
  def handle_call(:get_graph, _requester, fbp_graph) do
    {:reply, fbp_graph.graph, fbp_graph}
  end

  @doc """
  A request to clear the FBP Graph
  """
  def handle_call(:clear, _requester, fbp_graph) do
    :digraph.delete(fbp_graph.graph)
    digraph = :digraph.new()
    new_fbp_graph = %{fbp_graph | digraph: digraph}
    {:reply, nil, new_fbp_graph }
  end

  def handle_cast(message, fbp_graph) do
  end
end