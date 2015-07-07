defmodule SmartBunny do
  use Application
  require Logger

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    tunnel = Application.get_env(:smartbunny, :tunnel)
    children = [
      worker(SmartBunny.Tunnel, [tunnel]),
      supervisor(SmartBunny.Peers.Supervisor, []),
    ]
    opts = [strategy: :one_for_one, name: SmartBunny.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
