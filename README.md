ElixirFBP
=========

This repository will contain an implementation of Flow-based Programming in the
[Elixir language](http://elixir-lang.org). For more on FBP, see [Wikipedia](http://en.wikipedia.org/wiki/Flow-based_programming),
[J. Paul Morrison](http://www.jpaulmorrison.com/fbp/), and [NoFlo](http://noflojs.org)

This implementation is discussed [here](http://www.elixirfbp.org).

# Description
The Elixir implementation of the FBP runtime is based on the FBP Protocol as
described at the NoFlo [website](http://noflojs.org/documentation/protocol/).
Currently, the runtime can only communicate via websockets, which means that the
noflo-ui can be used either running locally or via the on-line version at
[app.flowhub.io](http:/app.flowhub.io).

#Architecture
Exclusive of the web socket handling (handled by the
[Cowboy](https://hex.pm/packages/cowboy) package) the
ElixirFBP consists of a set of Elixir modules:
* ElixirFBP.Runtime
* ElixirFBP.Network
* ElixirFBP.Graph

These three modules are implemented as Elixir [GenServers](http://elixir-lang.org/docs/stable/elixir/GenServer.html)

ElixirFBP.Runtime is responsible for communicating with a client who understands
the FBP network protocol and for keeping track of the graph that is being built/run.
It knows how to handle FBP protocol runtime commands.

ElixirFBP.Network
keeps track of the FBP network that is currently being built and/or run. It
knows how to handle FBP protocol network commands.

ElixirFBP.Graph keeps track of the FBP graph that is currently being built and/or
run. It knows how to handle FBP protocol graph commands.

# Limitations
* The components for this runtime are hard-wired in ElixirFBP. A "discovery"
mechanism to locate Elixir components will be implemented in a future release.
