defmodule SmartBunny.Tunnel do
  def make_tunnel(opt) do
    {:ok, dev} = :tuncer.create(opt.name, [:tun, :no_pi, {:active, true}])
    :ok = :tuncer.up(dev, opt.ip)
    dev
  end
  
end

defmodule SmartBunny.Tunnel.Client do
  use GenServer
  require Logger
  require Record
  alias SmartBunny.Tunnel, as: Tunnel

  Record.defrecordp :state, [
    tunnel: nil,
    peers: {},
    seed: nil,
  ]

  def start_link(opt) do
    GenServer.start_link(__MODULE__, opt, [name: __MODULE__])
  end

  def register_peer() do
    GenServer.call(__MODULE__, :register_peer)
  end

  def forward(packet) do
    GenServer.cast(__MODULE__, {:forward, packet})
  end

  # callback
  def init(opt) do
    tunnel = Tunnel.make_tunnel(opt)
    {:ok, state(tunnel: tunnel, seed: :random.seed())}
  end

  def handle_call(:register_peer, {from, _}, state) do
    peers = :erlang.append_element(state(state, :peers), from)
    {:reply, :ok, state(state, peers: peers)}
  end

  def handle_cast({:forward, packet}, state) do
    tunnel = state(state, :tunnel)
    :ok = :tuncer.send(tunnel, packet)
    {:noreply, state}
  end

  def handle_info({:tuntap, _dev, data}, state) do
    Logger.debug("recv tun data #{:erlang.size(data)}")
    state(peers: peers, seed: seed) = state
    len = tuple_size(peers)
    {idx, seed} = :random.uniform_s(len, seed)
    peer = elem(peers, idx - 1)
    SmartBunny.Peers.Worker.Client.forward(peer, data)
    {:noreply, state(state, seed: seed)}
  end

  # internal
end

defmodule SmartBunny.Tunnel.Server do
  use GenServer
  require Logger
  require Record
  alias SmartBunny.Tunnel, as: Tunnel

  Record.defrecordp :state, [
    tunnel: nil,
  ]

  def start_link(opt) do
    GenServer.start_link(__MODULE__, opt, [name: __MODULE__])
  end
  
  def forward(packet) do
    GenServer.cast(__MODULE__, {:forward, packet})
  end

  # callback
  def init(opt) do
    tunnel = Tunnel.make_tunnel(opt)
    {:ok, state(tunnel: tunnel)}
  end

  def handle_cast({:forward, packet}, state) do
    tunnel = state(state, :tunnel)
    :ok = :tuncer.send(tunnel, packet)
    {:noreply, state}
  end

  def handle_info({:tuntap, _dev, data}, state) do
    Logger.debug("recv tun data #{:erlang.size(data)}")
    SmartBunny.Peers.Worker.Server.forward(data)
    {:noreply, state}
  end

  # internal
end
