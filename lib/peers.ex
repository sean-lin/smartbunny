defmodule SmartBunny.Peers.Supervisor do
  use Supervisor 
  require Logger
  
  def start_link() do
    Supervisor.start_link(__MODULE__, [], [name: SmartBunny.Peers.Supervisor])
  end
 
  
  # callback
  def init([]) do
    import Supervisor.Spec, warn: false

    children = case Application.get_env(:smart_bunny, :mode) do
      :server ->
        [opt] = Application.get_env(:smart_bunny, :local)
        [worker(SmartBunny.Peers.Worker.Server, [opt])]
      :client ->
        Application.get_env(:smart_bunny, :local)
        |> Enum.map(fn x -> 
          worker(SmartBunny.Peers.Worker.Client, [x])
        end)
    end
    opts = [strategy: :one_for_one, name: SmartBunny.Peers.Supervisor]
    supervise(children, opts)
  end
end

defmodule SmartBunny.Peers do
  def bind_socket!(opt) do
    procket_opt = [protocol: :udp, type: :dgram, family: :inet, reuseaddr: true]
    {:ok, fd} = :procket.open(opt.port, procket_opt)
    :ok = :packet.bindtodevice(fd, String.to_char_list(opt.interface))
    {:ok, socket} = :gen_udp.open(0, 
      [:binary, {:fd, fd}, {:active, true}, {:reuseaddr, true}])
    socket
  end

end

defmodule SmartBunny.Peers.Worker.Client do
  use GenServer
  require Logger
  require Record

  alias SmartBunny.Tunnel.Client, as: Tunnel 
  alias SmartBunny.Peers, as: Peers
  alias SmartBunny.Packet, as: Packet

  Record.defrecordp :state, [
    socket: nil,
    remote_ip: nil,
    remote_port: nil, 
    cookie: nil,
  ]

  def start_link(opt) do
    GenServer.start_link(__MODULE__, opt)
  end

  def forward(pid, packet) do
    GenServer.cast(pid, {:forward, packet})
  end

  # callback
  def init(opt) do
    socket = Peers.bind_socket!(opt) 

    remote = Application.get_env(:smart_bunny, :remote)
    cookie = Application.get_env(:smart_bunny, :cookie)
    state = state(
      socket: socket, 
      remote_ip: remote.ip,
      remote_port: remote.port,
      cookie: Packet.cookie(cookie),
    )
    Tunnel.register_peer() 
    {:ok, state}
  end

  def handle_cast({:forward, data}, state) do
    state(
      socket: socket, 
      remote_ip: ip, remote_port: port, cookie: cookie) = state
    packet = Packet.pack(data, cookie, 0)
    send_to(socket, ip, port, packet)
    {:noreply, state}
  end

  def handle_info({:udp, _socket, ip, port, data}, state) do
    state(cookie: cookie)=state
    {data, scookie, timestamp, seqno} = Packet.unpack(data)
    
    Logger.debug("recv msg from #{inspect(ip)}:#{port}")
    if cookie == scookie do
      Tunnel.forward(data)
    else
      Logger.info("error cookie")
    end
    {:noreply, state}
  end

  # internal api
  defp send_to(socket, ip, port, packet) do
    :gen_udp.send(socket, ip, port, packet)
  end
end

defmodule SmartBunny.Peers.Worker.Server do
  use GenServer
  require Logger
  require Record

  alias SmartBunny.Tunnel.Server, as: Tunnel 
  alias SmartBunny.Peers, as: Peers
  alias SmartBunny.Packet, as: Packet

  Record.defrecordp :state, [
    socket: nil,
    remotes: nil,
    seed: nil,
    cookie: nil,
  ]

  def start_link(opt) do
    GenServer.start_link(__MODULE__, opt, [name: __MODULE__])
  end

  def forward(packet) do
    GenServer.cast(__MODULE__, {:forward, packet})
  end

  # callback
  def init(opt) do
    socket = Peers.bind_socket!(opt) 
    cookie = Application.get_env(:smart_bunny, :cookie)

    state = state(
      socket: socket, 
      remotes: [],
      seed: :random.seed(),
      cookie: Packet.cookie(cookie),
    )
    {:ok, state}
  end

  def handle_cast({:forward, data}, state) do
    state(socket: socket, seed: seed, remotes: remotes, cookie: cookie) = state
    {ip, port, seed, remotes} = choice_remotes(remotes, seed)
    packet = Packet.pack(data, cookie, 0)
    send_to(socket, ip, port, packet)
    {:noreply, state}
  end

  def handle_info({:udp, _socket, ip, port, packet}, state) do
    Logger.debug("recv msg from #{inspect(ip)}:#{port}")
    state(remotes: remotes, cookie: cookie) = state
    {data, scookie, timestamp, seqno} = Packet.unpack(packet)
    if cookie == scookie do
      remotes = add_remotes(remotes, {ip, port})
      Tunnel.forward(data)
    else
      Logger.debug("error cookie")
    end
    {:noreply, state(state, remotes: remotes)}
  end

  # internal api
  defp send_to(socket, ip, port, packet) do
    :gen_udp.send(socket, ip, port, packet)
    Logger.debug("packet sendto #{inspect(ip)}:#{port}")
  end

  defp choice_remotes(remotes, seed) do
    len = length(remotes) 
    {idx, seed} = :random.uniform_s(len, seed)
    {ip, port} = :lists.nth(idx, remotes)
    {ip, port, seed, remotes}
  end

  defp add_remotes(remotes, new) do
    case :lists.member(new, remotes) do
      true ->
        remotes
      false ->
        [new | remotes]
    end
  end
end
