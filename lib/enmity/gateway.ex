defmodule Enmity.Gateway do
  use GenServer
  require Logger

  def start_link(_args) do
    GenServer.start_link(__MODULE__, :ok)
  end

  def connected?(pid) do
    GenServer.call(pid, :is_connected)
  end

  def init(:ok) do
    {:ok, %{connected: false}, 0}
  end

  def handle_call(:is_connected, _from, state = %{connected: connected}) do
    {:reply, connected, state}
  end

  def handle_info(:timeout, state) do
    {:ok, %{url: url}} = Enmity.HTTP.get("/gateway/bot") |> Enmity.HTTP.make_response_nicer()
    parsed_url = URI.parse(url)
    {:ok, conn_pid} = :gun.open(to_charlist(parsed_url.host), 443, %{protocols: [:http]})

    state = state
    |> Map.put(:connect_url, url)
    |> Map.put(:conn, conn_pid)
    |> Map.put(:last_sequence_number, nil)

    {:noreply, state}
  end

  def handle_info(:heartbeat, state = %{conn: conn_pid, last_sequence_number: seq, heartbeat_interval_ms: heartbeat_interval_ms}) do
    :gun.ws_send(conn_pid, Poison.encode!(%{o: 1, d: seq}))
    Process.send_after(self(), :heartbeat, heartbeat_interval_ms)
    {:noreply, state}
  end

  def handle_info({:gun_ws, _ConnPid, _StreamRef, frame}, state = %{conn: conn_pid}) do
    body = Poison.decode!(frame)

    Logger.debug("Recieved websocket message #{frame}")

    case body["o"] do
      # regular message dispatch
      0 ->
        case body["t"] do
          "Ready" -> Logger.debug("Successfully set up a connection!!!!")
          something -> Logger.debug("Got an event I don't recognize: #{something}")
        end
        {:noreply, %{state | connected: true}}
      # hello message
      10 ->
        heartbeat_interval_ms = body["d"]["heartbeat_interval"]
        Process.send_after(self(), :heartbeat, heartbeat_interval_ms)

        {_osfamily, osname} = :os.type()

        :gun.ws_send(conn_pid, Poison.encode!(%{o: 2, d: %{
          token: Application.fetch_env!(:enmity, :token),
          properties: %{
            "$os": osname,
            "$browser": "enmity",
            "$device": "enmity"
          }
        }}))
        {:noreply, Map.put(state, :heartbeat_interval_ms, heartbeat_interval_ms)}
      # heartbeat ack
      11 ->
        {:noreply, state}
    end

    {:noreply, state}
  end

  def handle_info({:gun_upgrade, _conn_pid, _stream_ref, _, _}, state) do
    Logger.debug("Successfully upgraded to a websocket connection")
    {:noreply, state}
  end

  def handle_info({:gun_up, conn_pid, _protocol}, state = %{connect_url: url}) do
    Logger.debug("Connection to host successful, upgrading to websocket connection")
    parsed_url = URI.parse(url)
    :gun.ws_upgrade(conn_pid, to_charlist("#{parsed_url.path}?v=6&encoding=json"))

    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.debug("Got an unrecognized message: #{inspect msg}")
    {:noreply, state}
  end
end
