defmodule SmartBunny.Remote do
  use GenServer
  require Logger
  require Record

  Record.defrecordp :state, [
    tunnel: nil,
  ]

  def start_link(opt) do
    GenServer.start_link(__MODULE__, opt, [name: __MODULE__])
  end

  # callback
  def init(opt) do
    tunnel = make_tunnel(opt)
    {:ok, state(tunnel: tunnel)}
  end

  # internal
  defp make_tunnel(opt) do
    {:ok, dev} = :tuncer.create(opt.name, [:tun, :no_pi, {:active, true}])
    :ok = :tuncer.up(dev, opt.ip)
    dev
  end
end
