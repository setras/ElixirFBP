defmodule ElixirFBP.Graph do
  @moduledoc """
  ElxirFBP.Graph is a GenServer that provides support for the creation and
  maintainance of an FBP Graph.

  An FBP graph contains Nodes connected by Edges. Facilities are provided for
  the creation, deletion, and modification of nodes and edges. Initial Information
  Packets (IIP's) can also be specified.

  Graphs are implemented using Erlang's digraph library.

  The digraph Label associated with a node (digraph vertex) is
  [component, inports, inport_types, outports, outport_types, metadata] where
  component is the string name of a component e.g., "Math.Add". inports
  and outports are lists of atomic name, initial value pairs, e.g., {:augend, 2} and
  inport_types and outport_types are lists of atomic name, type, e.g., {:augend, :integer}.

  Initial values can be set using the add_initial graph command.

  The digraph Label associated with an edge is [src.port,, tgt.port, metadata] where src.port
  and tgt.port are atom values for the component's ports.

  Functions supported by this module are based on NoFlo's FBP Network Protocol,
  specifically the graph sub-protocol. See http://noflojs.org/documentation/protocol/
  for the details.

  TODO: Provide support for Port and Group maintenance.
  TODO: Use secret parameter
  TODO: Handle :digraph errors
  TODO: Metadata needs to be stored somewhere in add_initial()

  """
  defstruct [
    id: "",
    name: "",
    library: nil,
    main: false,
    icon: nil,
    description: "",
    registered_name: nil,
    running: false,
    started: false,
    graph: nil
  ]
  @type t :: %__MODULE__{
                id: String.t,
                name: String.t,
                library: module,
                main: boolean,
                icon: String.t,
                description: String.t,
                registered_name: atom,
                running: boolean,
                started: boolean,
                graph: atom}

  use GenServer

  ########################################################################
  # The External API

  @doc """
  Starts things off with the creation of the state. Register it with the name
  graph_id - converted to an atom.
  """
  def start_link(graph_id, parameters \\ %{}) do
    registered_name = String.to_atom(graph_id)
    {:ok, _pid} = GenServer.start_link(__MODULE__,
                                      [graph_id, registered_name, parameters],
                                      name: registered_name)
    {:ok, registered_name}
  end

  @doc """
  Set the parameters associated with this graph
  """
  def set_parameters(fbp_graph_reg_name, parameters \\ %{}) do
    GenServer.call(fbp_graph_reg_name, {:set_parameters, parameters})
  end

  @doc """
  Start the execution of the components in this graph. Optionally supplying
  a run mode of :pull or :push (default)
  """
  def start(fbp_graph_reg_name, run_mode \\ :push) do
    GenServer.call(fbp_graph_reg_name, {:start, run_mode})
  end

  @doc """
  Stop the execution of the components in this graph.
  This should normally be called via the Network.stop(graph_id) function.
  """
  def stop_graph(fbp_graph_reg_name) do
    GenServer.call(fbp_graph_reg_name, :stop_graph)
  end

  @doc """
  Retreive the FBP Graph structure - primarily used for testing/debugging
  """
  def get(fbp_graph_reg_name) do
    GenServer.call(fbp_graph_reg_name, :get)
  end

  @doc """
  Return the status variables for this graph
  """
  def get_status(fbp_graph_reg_name) do
    GenServer.call(fbp_graph_reg_name, :get_status)
  end

  @doc """
  Return the current list of nodes
  """
  def nodes(fbp_graph_reg_name) do
    GenServer.call(fbp_graph_reg_name, :nodes)
  end

  @doc """
  Return info about a node.
  """
  def get_node(fbp_graph_reg_name, node_id) do
    GenServer.call(fbp_graph_reg_name, {:get_node, node_id})
  end

  @doc """
  Return the current list of edges - primarily used for testing/debugging.
  """
  def edges(fbp_graph_reg_name) do
    GenServer.call(fbp_graph_reg_name, :edges)
  end

  @doc """
  Return the edges attached to a node
  """
  def edges(fbp_graph_reg_name, node_id) do
    GenServer.call(fbp_graph_reg_name, {:edges, node_id})
  end

  @doc """
  Add a node to the FBP Graph. Note the number of default processes is 1.
  """
  def add_node(fbp_graph_reg_name, node_id, component, metadata \\ %{}) do
    if ! Map.has_key?(metadata, :number_of_processes) do
      metadata = Map.merge(metadata, %{:number_of_processes => 1})
    end
    GenServer.call(fbp_graph_reg_name, {:add_node, node_id, component, metadata})
  end

  @doc """
  Remove a node from an FBP Graph
  """
  def remove_node(fbp_graph_reg_name, node_id) do
    GenServer.call(fbp_graph_reg_name, {:remove_node, node_id})
  end

  @doc """
  Rename a node in an FBP Graph
  """
  def rename_node(fbp_graph_reg_name,
                  from,
                  to,
                  secret) do
    GenServer.call(fbp_graph_reg_name,
          {:rename_node, from, to, secret})
  end

  @doc """
  Change the metadata associated with a node in a graph
  """
  def change_node(fbp_graph_reg_name,
                  node_id,
                  metadata,
                  secret) do
    GenServer.call(fbp_graph_reg_name, {:change_node, node_id, metadata, secret})
  end

  @doc """
  Add an edge to the FBP Graph
  """
  def add_edge(fbp_graph_reg_name,
                src_node_id, src_port,
                tgt_node_id, tgt_port,
                metadata \\ %{}) do
    GenServer.call(fbp_graph_reg_name,
          {:add_edge, src_node_id, src_port, tgt_node_id, tgt_port, metadata})
  end

  @doc """
  Remove the edge between the two given node/ports in an FBP Graph
  """
  def remove_edge(fbp_graph_reg_name,
                  src_node_id, src_port,
                  tgt_node_id, tgt_port) do
    GenServer.call(fbp_graph_reg_name,
          {:remove_edge, src_node_id, src_port, tgt_node_id, tgt_port})
  end

  @doc """
  Change an edge's metadata in an FBP Graph
  """
  def change_edge(fbp_graph_reg_name,
                  src_node_id, src_port,
                  tgt_node_id, tgt_port,
                  metadata,
                  secret) do
    GenServer.call(fbp_graph_reg_name,
        {:change_edge, src_node_id, src_port, tgt_node_id, tgt_port, metadata, secret})
  end

  @doc """
  Get the subscription pid for this edge.
  """
  def get_subscription(fbp_graph_reg_name,
                     src_node_id, src_port,
                     tgt_node_id, tgt_port) do
    GenServer.call(fbp_graph_reg_name,
        {:get_subscription,src_node_id, src_port, tgt_node_id, tgt_port})
  end

  @doc """
  Place an initial value at the port of a node in and FBP Graph
  """
  def add_initial(fbp_graph_reg_name, data, node_id, port, metadata \\ %{}) do
    GenServer.call(fbp_graph_reg_name, {:add_initial, data, node_id, port, metadata})
  end

  @doc """
  Remove an initial value at the port of a node in the FBP Graph. It is set to
  the value nil.
  """
  def remove_initial(fbp_graph_reg_name, node_id, port, secret) do
    GenServer.call(fbp_graph_reg_name, {:remove_initial, node_id, port, secret})
  end

  @doc """
  Stop this GenServer
  """
  def stop(fbp_graph_reg_name) do
    GenServer.call(fbp_graph_reg_name, :stop)
  end

  ##############################################################################
  # The GenServer implementations

  @doc """
  Callback implementation for ElixirFBP.Graph.clear()
  Create and initialize the FBP Graph Structure which becomes the State
  """
  def init([graph_id, registered_name, parameters]) do
    # The digraph is where all the nodes and edges are stored
    graph = :digraph.new([:protected])
    fbp_graph = %ElixirFBP.Graph{id: graph_id,
                                 name: parameters[:name],
                                 library: parameters[:library],
                                 main: parameters[:main],
                                 icon: parameters[:icon],
                                 description: parameters[:description],
                                 registered_name: registered_name,
                                 graph: graph}
    {:ok, fbp_graph}
  end

  @doc """
  Callback implementation of ElixirFBP.Graph.set_parameters()
  Set the parameters associated with this registered graph
  """
  def handle_call({:set_parameters, parameters}, _req, fbp_graph) do
    new_fbp_graph = %ElixirFBP.Graph{fbp_graph |
                                    name: parameters[:name],
                                    library: parameters[:library],
                                    main: parameters[:main],
                                    icon: parameters[:icon],
                                    description: parameters[:description]}
    {:reply, :ok, new_fbp_graph}
  end

  @doc """
  Callback implementation of ElixirFBP.Graph.start()
  Starting a graph involves the following steps:
    1. Verify that all outports are connected to something
    2. For every edge in the graph, create and spawn a Subscription
    3. For every node in the graph, assemble the inports and outport values
       for a Component and then spawn the Component's process(es)
    4. Choose the method to begin execution based on the run_mode - either
       :push or :pull mode.

  """
  def handle_call({:start, run_mode}, _req, fbp_graph) do
    nodes = :digraph.vertices(fbp_graph.graph)
    edges = :digraph.edges(fbp_graph.graph)
    # Verify that all out ports on all the nodes are connected to something
    problems = verify_out_ports(fbp_graph.graph)
    case problems do
      [] ->
        # Start a subscription for each edge; save the subscription's pid in a
        # Map for later lookup. The key values are the tuples {node_in, src_port}
        # and {node_out, tgt_ports}
        subscription_map = Enum.map(edges, fn(edge) ->
          {_edge_id, node_in, node_out, label} = :digraph.edge(fbp_graph.graph, edge)
          %{src_port: src_port, tgt_port: tgt_port} = label
          subscription_pid = ElixirFBP.Subscription.start(src_port, tgt_port)
          # Process.register(subscription_pid, :sub1)
          new_label = %{label | :subscription_pid => subscription_pid}
          :digraph.add_edge(
                          fbp_graph.graph,
                          edge,
                          node_in,
                          node_out,
                          new_label)
          [{{node_in, src_port}, subscription_pid},
           {{node_out, tgt_port}, subscription_pid}]
        end) |> List.flatten() |> Enum.into(%{})
        # Create the initial inport and outport values for a Component.
        # Spawn 1 or more processes for a Component
        Enum.each(nodes, fn(node) ->
          {node_id, label} = :digraph.vertex(fbp_graph.graph, node)
          %{component: component, inports: inports, outports: outports} = label
          # inports will have either a Subscription pid or an initial value
          inps = Enum.map(inports, fn
            {inport, nil} ->
              subscription_pid = Map.get(subscription_map, {node_id, inport})
              {inport, subscription_pid}
            {inport, value} ->
              {inport, value}
            end) |> Enum.into(%{})
          # outports will have a Subscription pid as a value
          outps = Enum.map(outports, fn({outport, _}) ->
            subscription_pid = Map.get(subscription_map, {node_id, outport})
            {outport, subscription_pid}
          end) |> Enum.into(%{})
          # IO.puts("Component.start: #{component},#{node_id},#{inspect inps},#{inspect outps}")
          component_pids = ElixirFBP.Component.start(component, node_id, inps, outps)
          new_label = %{label | :component_pids => component_pids}
          :digraph.add_vertex(fbp_graph.graph, node_id, new_label)
        end)
        # Get things started conditioned on whether this graph is to run
        # in a push or pull mode
        case run_mode do
          :push ->
            # Find all of the initial information packet components and make
            # each of them send an information packet to their respective subscribers
            Enum.each(nodes, fn(node) ->
              {_vertex,
                %{component: component,
                  component_pids: component_pids} = label} = :digraph.vertex(fbp_graph.graph, node)
              if component == "ElixirFBP.InitialInformationPacket" do
                Enum.each(component_pids, fn(component_pid) ->
                  send(component_pid, :value)
                end)
              end
            end)
          :pull ->
            # For all of the subscriptions, send them a request message. request
            # capacity values from the subscription's publisher.
            Enum.each(edges, fn(edge) ->
              {_edge_id, _node_in, _node_out, label} =
                    :digraph.edge(fbp_graph.graph, edge)
              %{subscription_pid: subscription_pid} = label
              send(subscription_pid, :request)
            end)
          _ ->
            nil
        end
        new_fbp_graph = %ElixirFBP.Graph{fbp_graph | started: true, running: true}
        {:reply, :ok, new_fbp_graph}
      _ ->
        # There were problems whilst checking the out ports
        {:reply, problems, fbp_graph}
    end
  end

  @doc """
  Callback implementation of ElxirFBP.Graph.get()
  Return the FBP Graph structure
  """
  def handle_call(:get, _req, fbp_graph) do
    {:reply, fbp_graph, fbp_graph}
  end

  @doc """
  Callback implementation of ElixirFBP.Graph.get_status()
  Return the status variables as a tuple.
  """
  def handle_call(:get_status, _req, fbp_graph) do
    {:reply, {fbp_graph.running, fbp_graph.started}, fbp_graph}
  end

  @doc """
  Callback implementation of ElixirFBP.Graph.nodes()
  Return the current list of nodes.
  """
  def handle_call(:nodes, _req, fbp_graph) do
    {:reply, :digraph.vertices(fbp_graph.graph), fbp_graph}
  end

  @doc """
  Callback implementation of ElixirFBP.Graph.get_node()
  Returns {vertex, label}
  """
  def handle_call({:get_node, node_id}, _req, fbp_graph) do
    graph = fbp_graph.graph
    {:reply, :digraph.vertex(graph, node_id), fbp_graph}
  end

  @doc """
  Callback implementation of ElixirFBP.Graph.edges()
  Return the current list of edges.
  """
  def handle_call(:edges, _req, fbp_graph) do
    {:reply, :digraph.edges(fbp_graph.graph), fbp_graph}
  end

  @doc """
  Callback implementation for ElixirFBP.Graph.edges(node_id)
  Return the edges for a given node
  """
  def handle_call({:edges, node_id}, _req, fbp_graph) do
    out_edges = :digraph.out_edges(fbp_graph.graph, node_id)
    in_edges = :digraph.in_edges(fbp_graph.graph, node_id)
    edges = Enum.map(out_edges ++ in_edges, fn(edge) ->
      {_edge_id, _node_in, _node_out, label} =
            :digraph.edge(fbp_graph.graph, edge)
      %{subscription_pid: subscription_pid} = label
    end)
    {:reply, :ok, fbp_graph}
  end

  @doc """
  Callback implementation for ElixirFBP.Graph.add_node()
  """
  def handle_call({:add_node, node_id, component, metadata}, _req, fbp_graph) do
    component_inports = elem(Code.eval_string(component <> ".inports"), 0)
    component_outports = elem(Code.eval_string(component <> ".outports"), 0)
    # Construct a list of port name, value pairs that will be used to hold
    # initial values.
    inports = Enum.map(component_inports, fn(inport) ->
      {elem(inport,0), nil}
      end)
    outports = Enum.map(component_outports, fn(outport) ->
      {elem(outport,0), nil}
      end)
    label = %{component: component,
              component_pids: [],
              inports: inports, inport_types: component_inports,
              outports: outports, outport_types: component_outports,
              metadata: metadata}
    new_vertex = :digraph.add_vertex(fbp_graph.graph, node_id, label)
    {:reply, new_vertex, fbp_graph}
  end

  @doc """
  Callback implementation for ElixirFBP.Graph.remove_node()
  """
  def handle_call({:remove_node, node_id}, _req, fbp_graph) do
    result = :digraph.del_vertex(fbp_graph.graph, node_id)
    {:reply, result, fbp_graph}
  end

  @doc """
  Callback implementation for ElixirFBP.Graph.rename_node()
  """
  def handle_call({:rename_node, from, to, secret}, _req, fbp_graph) do
    {_vertex, label} = :digraph.vertex(fbp_graph.graph, from)
    new_vertex = :digraph.add_vertex(fbp_graph.graph, to, label)
    :digraph.del_vertex(fbp_graph.graph, from)
    {:reply, new_vertex, fbp_graph}
  end

  @doc """
  Callback implementation for ElixirFBP.Graph.change_node()
  """
  def handle_call({:change_node, id, metadata, secret}, _req, fbp_graph) do
    {_vertex, label} = :digraph.vertex(fbp_graph.graph, id)
    current_metadata = label.metadata
    new_metadata = Map.merge(current_metadata, metadata)
    new_label = %{label | :metadata => new_metadata}
    new_vertex = :digraph.add_vertex(fbp_graph.graph, id, new_label)
    {:reply, new_vertex, fbp_graph}
  end

  @doc """
  Callback implementation for ElixirFBP.Graph.add_edge()
  """
  def handle_call({:add_edge,
                    src_node_id, src_port,
                    tgt_node_id, tgt_port,
                    metadata}, _req, fbp_graph) do
    label = %{src_port: src_port, tgt_port: tgt_port, metadata: metadata, subscription_pid: nil}
    new_edge = :digraph.add_edge(
                    fbp_graph.graph,
                    src_node_id,
                    tgt_node_id,
                    label)
    {:reply, new_edge, fbp_graph}
  end

  @doc """
  Callback implementation for ElixirFBP.Graph.remove_edge()
  """
  def handle_call({:remove_edge,
                    src_node_id, _src_port,
                    tgt_node_id, _tgt_port},
                    _req, fbp_graph) do
    result = :digraph.del_path(fbp_graph.graph, src_node_id, tgt_node_id)
    {:reply, result, fbp_graph}
  end

  @doc """
  Callback implementation for ElixirFBP.Graph.change_edge()
  """
  def handle_call({:change_edge,
                    src_node_id, _src_port,
                    tgt_node_id, _tgt_port,
                    metadata, secret},
                    _req, fbp_graph) do
    edges = :digraph.out_edges(fbp_graph.graph, src_node_id)
    Enum.each(edges, fn(edge) ->
      {_, _, node, label} = :digraph.edge(fbp_graph.graph, edge)
      if node == tgt_node_id do
        current_metadata = label.metadata
        new_metadata = Map.merge(current_metadata, metadata)
        new_label = %{label | :metadata => new_metadata}
        :digraph.add_edge(
                        fbp_graph.graph,
                        edge,
                        src_node_id,
                        tgt_node_id,
                        new_label)
      end
    end)
    {:reply, nil, fbp_graph}
  end

  @doc """
  Callback implementation for ElixirFBP.Graph.get_subscription()
  """
  def handle_call({:get_subscription,
                    src_node_id, _src_port,
                    tgt_node_id, _tgt_port}, _req, fbp_graph) do
    edges = :digraph.out_edges(fbp_graph.graph, src_node_id)
    subscription_pids = Enum.map(edges,
        fn(edge) ->
          {_, _, node, label} = :digraph.edge(fbp_graph.graph, edge)
          if node == tgt_node_id do
            %{:subscription_pid => subscription_pid} = label
            subscription_pid
          end
        end)
    {:reply, subscription_pids, fbp_graph}
  end

  @doc """
  Callback implementation for ElixirFBP.Graph.add_initial(). We create a node
  using the distinguished component named InitialInformationPacket. This node
  is preloaded with the initial value. We also add an edge from the given node
  (node_id) to this initial component node. The edge will later be the basis
  for spawning a Subscription.
  """
  def handle_call({:add_initial, data, node_id, port, _metadata}, _req, fbp_graph) do
    inports = [constant: data]
    outports = [value: :any]
    label = %{component: "ElixirFBP.InitialInformationPacket",
              component_pids: [],
              inports: inports, inport_types: [:any], metadata: %{:number_of_processes => 1},
              outports: outports, outport_types: []}
    iip_node_id = node_id <> "_" <> Atom.to_string(port)
    iip_node = :digraph.add_vertex(fbp_graph.graph, iip_node_id, label)
    # Now construct an edge between this IIP node and the node that will be
    # initialized - designated by node_id
    edge_label =  %{src_port: :value,
                    tgt_port: port,
                    subscription_pid: nil}
    new_edge = :digraph.add_edge(
                    fbp_graph.graph,
                    iip_node_id,
                    node_id,
                    edge_label)
    {:reply, iip_node, fbp_graph}
  end

  @doc """
  Callback implementation for ElixirFBP.Graph.remove_initial()
  """
  def handle_call({:remove_initial, node_id, port, secret}, _req, fbp_graph) do
    {node_id, label} = :digraph.vertex(fbp_graph.graph, node_id)
    inports = label.inports
    new_inports = Keyword.put(inports, port, nil)
    new_label = %{label | :inports => new_inports}
    :digraph.add_vertex(fbp_graph.graph, node_id, new_label)
    {:reply, nil, fbp_graph}
  end

  @doc """
  Callback implementation for ElixirFBP.Graph.stop()
  Stop the execution of a graph.
  Unregister and kill all of the node processes.
  """
  def handle_call(:stop_graph, _req, fbp_graph) do
    reg_name = fbp_graph.registered_name
    nodes = :digraph.vertices(fbp_graph.graph)
    Enum.each(nodes, fn(node) ->
      {node_id, label} = :digraph.vertex(fbp_graph.graph, node)
      ElixirFBP.Component.stop(reg_name, node_id, label) end)
      new_fbp_graph = %ElixirFBP.Graph{fbp_graph | running: false, started: false}
    {:reply, :ok, new_fbp_graph}
  end

  @doc """
  Callback implementation for stopping this GenServer.
  """
  def handle_call(:stop, _req, fbp_graph) do
    # Graph.stop(fbp_graph.registered_name)
    {:stop, :normal, :ok, fbp_graph}
  end

  @doc """
  Callback implementation triggered by asking the GenServer to :stop
  """
  def terminate(_reason, _fbp_graph) do
    :ok
  end

  def verify_out_ports(graph) do
    nodes = :digraph.vertices(graph)
    Enum.reduce(nodes, [], fn(node, node_results) ->
      {_,%{outports: outports} = label} = :digraph.vertex(graph, node)
      if length(outports) > 0 do
        out_ports = :digraph.out_edges(graph, node)
        case out_ports do
          [] ->
            [{:error, "no outports are connected"} | node_results]
          _ ->
            o_p_results = Enum.reduce(out_ports, [], fn(out_port, out_port_results) ->
              case :digraph.edge(graph, out_port) do
                {_, _, nil, %{src_port: src_port} = label} ->
                  [{:error, src_port} | out_port_results]
                _ ->
                  out_port_results
              end
            end)
            case o_p_results do
              [] -> node_results
              _  -> [o_p_results | node_results]
            end
        end
      else
        node_results
      end
    end)
  end

  defp convert_to_type(:integer, data) when is_bitstring(data) do
    case Integer.parse(data) do
      {value, _} -> value
      :error -> {:error, "Invalid integer"}
    end
  end

  defp convert_to_type(:integer, data) when is_integer(data) do
    data
  end
  defp convert_to_type(:string, data) when is_bitstring(data) do
    data
  end
  defp convert_to_type(:string, data) do
    inspect data
  end
  defp convert_to_type(:pid, data) when is_pid(data) do
    data
  end
end
