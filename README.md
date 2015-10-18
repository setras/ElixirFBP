ElixirFBP
=========

This repository will contain an implementation of Flow-based Programming in the
[Elixir language](http://elixir-lang.org). For more on FBP, see [Wikipedia](http://en.wikipedia.org/wiki/Flow-based_programming),
[J. Paul Morrison](http://www.jpaulmorrison.com/fbp/), and [NoFlo](http://noflojs.org)

This implementation is discussed [here](http://www.elixirfbp.org).

# Description
The Elixir implementation of the FBP runtime is based on the FBP Protocol as
described at the NoFlo [website](http://noflojs.org/documentation/protocol/).

Note that an earlier release of this repository contained a runtime implementation
that communicated, via websockets, with noflo-ui. Noflow-ui can be used either
running locally or via the on-line version at
[app.flowhub.io](http:/app.flowhub.io). This code was refactored out and will
appear in another repository.

# Architecture
ElixirFBP is made up of the following Elixir modules:
* ElixirFBP.Runtime
* ElixirFBP.Network
* ElixirFBP.Graph
* ElixirFBP.Subscription

The first three modules are implemented as Elixir [GenServers](http://elixir-lang.org/docs/stable/elixir/GenServer.html)

ElixirFBP.Runtime is responsible for communicating with a client who understands
the FBP network protocol and for keeping track of the graph that is being built/run.
It knows how to handle FBP protocol runtime commands.

ElixirFBP.Network
keeps track of the FBP network that is currently being built and/or run. It
knows how to handle FBP protocol network commands.

ElixirFBP.Graph keeps track of the FBP graph that is currently being built and/or
run. It knows how to handle FBP protocol graph commands.

An ElixirFBP.Subscription serves as connection between any two components, hence
there is one Subscription per FBP graph edge. The components correspond to the
publisher and subscriber in the [Reactive Stream protocol](http://www.reactive-streams.org/). A Subscription can limit the number of Information Packets that can be sent from a
publisher to a subscriber, that is, "back pressure" can be applied to the
publisher.

# Limitations
* The components for this runtime are hard-wired in ElixirFBP. A "discovery"
mechanism to locate Elixir components will be implemented in a future release.
