defmodule Enmity.Gateway do
  use GenServer
  require Logger

  def start_link(_args) do
    GenServer.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    {:ok, nil, 0}
  end

  def handle_info(:timeout, _state) do
    {:ok, %{url: url}} = Enmity.HTTP.get("/gateway/bot") |> Enmity.HTTP.make_response_nicer()
    parsed_url = URI.parse(url)

    {:ok, conn_pid} = :gun.open(parsed_url.host, 443, protocols: [:http])
    :gun.ws_upgrade(conn_pid, "#{parsed_url.path}?v=6&encoding=json", ["Authorization": "Bot #{Application.fetch_env!(:enmity, :token)}"])

    {:noreply, %{conn: conn_pid, last_sequence_number: nil}}
  end

  def handle_info(:heartbeat, state = %{conn: conn_pid, last_sequence_number: seq, heartbeat_interval_ms: heartbeat_interval_ms}) do
    :gun.ws_send(conn_pid, Poison.encode!(%{o: 1, d: seq}))
    Process.send_after(self(), :heartbeat, heartbeat_interval_ms)
    {:noreply, state}
  end

  def handle_info({:gun_ws, _ConnPid, _StreamRef, frame}, state = %{conn: conn_pid}) do
    body = Poison.decode!(frame)

    case body["o"] do
      # regular message dispatch
      0 ->
        case body["t"] do
          "Ready" -> Logger.debug("Successfully set up a connection!!!!")
        end
        {:noreply, state}
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
        {:noreply, %{state | heartbeat_interval_ms: heartbeat_interval_ms}}
      # heartbeat ack
      11 ->
        {:noreply, state}
    end

    {:noreply, state}
  end

  def handle_info({:gun_upgrade, _conn_pid, _stream_ref, _, _}, state) do
    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end
end
