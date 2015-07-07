defmodule SmartBunny.Tunnel do
  use GenServer
  require Logger
  require Record

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

  # callback
  def init(opt) do
    tunnel = make_tunnel(opt)
    {:ok, state(tunnel: tunnel, seed: :random.seed())}
  end

  def handle_call(:register_peer, {from, _}, state) do
    peers = Tuple.to_list(state(state, :peers))
    peers = [from | peers ] |> List.to_tuple 
    {:reply, :ok, state(state, peers: peers)}
  end

  def handle_info({:tuntap, _dev, data}, state) do
    state(peers: peers, seed: seed) = state
    len = tuple_size(peers)
    {idx, seed} = :random.uniform_s(len, seed)
    peer = elem(peers, idx - 1)
    SmartBunny.Peers.Worker.forward(peer, data)
    {:noreply, state(state, seed: seed)}
  end

  # internal
  defp make_tunnel(opt) do
    {:ok, dev} = :tuncer.create(opt.name, [:tun, :no_pi, {:active, true}])
    :ok = :tuncer.up(dev, opt.ip)
    dev
  end
end
