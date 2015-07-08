defmodule SmartBunny do
  use Application
  require Logger

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    tunnel = Application.get_env(:smart_bunny, :tunnel)
    mode = Application.get_env(:smart_bunny, :mode) 
    Logger.info("start at #{mode}")
    mod = case mode do
      :server -> 
        SmartBunny.Tunnel.Server
      :client ->
        SmartBunny.Tunnel.Client
    end

    children = [
      worker(mod, [tunnel]),
      supervisor(SmartBunny.Peers.Supervisor, []),
    ]
    opts = [strategy: :one_for_one, name: SmartBunny.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
