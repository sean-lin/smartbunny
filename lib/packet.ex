defmodule SmartBunny.Packet do
  @mega  1000000

  def unpack(data) do 
    <<cookie::unsigned-big-integer-size(32), 
    timestamp::unsigned-big-integer-size(64),
    seqno::unsigned-big-integer-size(64),
    rest::binary>> = data
    {rest, cookie, timestamp, seqno}
  end
  def pack(data, cookie, seqno) do
    {m, s, _} = :erlang.now()
    timestamp = m * @mega + s
    <<cookie::unsigned-big-integer-size(32), 
    timestamp::unsigned-big-integer-size(64),
    seqno::unsigned-big-integer-size(64),
    data::binary>>
  end

  def cookie(cookie_str) do
    :erlang.phash2(cookie_str)
  end
end
