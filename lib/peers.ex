defmodule SmartBunny.Peers.Supervisor do
  use Supervisor 
  require Logger
  
  def start_link() do
    Supervisor.start_link(__MODULE__, [], [name: SmartBunny.Peers.Supervisor])
  end
 
  
  # callback
  def init([]) do
    import Supervisor.Spec, warn: false

    children = Application.get_env(:smartbunny, :local)
    |> Enum.map(fn x -> 
      worker(SmartBunny.Peers.Worker, [x])
    end)

    opts = [strategy: :one_for_one, name: SmartBunny.Peers.Supervisor]
    supervise(children, opts)
  end
end

defmodule SmartBunny.Peers.Worker do
  use GenServer
  require Logger
  require Record

  alias SmartBunny.Tunnel, as: Tunnel 

  Record.defrecordp :state, [
    socket: nil,
    remote_ip: nil,
    remote_port: nil, 
  ]

  def start_link(opt) do
    GenServer.start_link(__MODULE__, opt)
  end

  def forward(pid, packet) do
    GenServer.cast(pid, {:forward, packet})
  end

  # callback
  def init(opt) do
    socket = bind_socket!(opt) 

    remote = Application.get_env(:smartbunny, :remote)
    state = state(
      socket: socket, 
      remote_ip: remote.ip,
      remote_port: remote.port
    )
    Tunnel.register_peer() 
    {:ok, state}
  end

  def handle_cast({:forward, packet}, state) do
    state = send_to(state, packet)
    {:noreply, state}
  end

  def handle_info({:udp, _socket, _ip, _port, data}, state) do
    Tunnel.forward(data)
    {:noreply, state}
  end

  # internal api
  defp bind_socket!(opt) do
    procket_opt = [protocol: :udp, type: :dgram, family: :inet]
    {:ok, fd} = :procket.open(opt.port, procket_opt)
    :ok = :packet.bindtodevice(fd, String.to_char_list(opt.interface))
    {:ok, socket} = :gen_udp.open(0, [:binary, {:fd, fd}, {:active, true}])
    socket
  end

  defp send_to(state, packet) do
    state(socket: socket, remote_ip: ip, remote_port: port) = state
    :gen_udp.send(socket, ip, port, packet)
    state
  end
end
