defmodule Enmity.Gateway do
  @moduledoc """
  Connects to the Discord Gateway.

  Import this module with `Use` and define `handle_event/3` callbacks to receive events from Discord.

      defmodule MyGateway do
        use Enmity.Gateway

        def handle_event(:READY, data, state) do
          # We're connected! hooray!
          {:ok, state}
        end

        def handle_event(:GUILD_CREATE, data, state) do
          # This event will be sent after :READY, once for each guild your bot is a member of.
          {:ok, state}
        end
      end
  """


  defmacro __using__(_opts) do
    quote do
      use GenServer
      require Logger

      def start_link(_args) do
        GenServer.start_link(__MODULE__, :ok)
      end

      def connected?(pid) do
        GenServer.call(pid, :is_connected)
      end

      def init(:ok) do
        {:ok, %{connected: false, user_state: %{}}, 0}
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
        :gun.ws_send(conn_pid, {:binary, %{"op" => 1, "d" => seq, "t" => "HEARTBEAT"}})
        Process.send_after(self(), :heartbeat, heartbeat_interval_ms)
        {:noreply, state}
      end

      def handle_info({:gun_ws, _ConnPid, _StreamRef, {:binary, frame}}, state = %{conn: conn_pid}) do
        # body = Poison.decode!(frame)
        body = frame
        |> :erlang.iolist_to_binary()
        |> :erlang.binary_to_term()

        Logger.debug("Recieved websocket message #{inspect body}")

        case body.op do
          # regular message dispatch
          0 ->
            case body.t do
              :READY ->
                Logger.debug("Successfully set up a connection! data: #{inspect data}")
                {:ok, new_user_state} = handle_event(:READY, body.d, state.user_state)
                {:noreply, %{state | connected: true, user_state: new_user_state}}
              event ->
                {:ok, new_user_state} = handle_event(event, body.d, state.user_state)
                {:noreply, %{state | user_state: new_user_state}}
            end
          # hello message
          10 ->
            Logger.debug("Got a hello message, sending identifier frame")
            heartbeat_interval_ms = body.d.heartbeat_interval
            Process.send_after(self(), :heartbeat, heartbeat_interval_ms)

            {osfamily, osname} = :os.type()
            osname = "#{osfamily} #{to_string(osname)}"

            payload = %{
              "op" => 2,
              "t" => "IDENTIFY",
              "s" => Map.get(state, :last_sequence_number),
              "d" => %{
                "token" => Application.fetch_env!(:enmity, :token),
                "properties" => %{
                  "$os" => osname,
                  "$browser" => "enmity",
                  "$device" => "enmity"
                }
              }
            }
            |> :erlang.term_to_binary()

            :gun.ws_send(conn_pid, {:binary, payload})
            {:noreply, Map.put(state, :heartbeat_interval_ms, heartbeat_interval_ms)}
          # heartbeat ack
          11 ->
            {:noreply, state}
          _ ->
            {:noreply, state}
        end
      end

      def handle_info({:gun_upgrade, _conn_pid, _stream_ref, _, _}, state) do
        Logger.debug("Successfully upgraded to a websocket connection")
        {:noreply, state}
      end

      def handle_info({:gun_up, conn_pid, _protocol}, state = %{connect_url: url}) do
        Logger.debug("Connection to host successful, upgrading to websocket connection")
        parsed_url = URI.parse(url)
        stream_ref = :gun.ws_upgrade(
          conn_pid,
          '/?encoding=etf&v=6')

        {:noreply, Map.put(state, :stream_ref, stream_ref)}
      end

      def handle_info(msg, state) do
        Logger.debug("Got an unrecognized message: #{inspect msg}")
        {:noreply, state}
      end
    end
  end

  @doc """
  Handle a Discord Gateway event.

  Event names are tokens in all-caps, like `:READY`.

  For a full list of events, see [Discord's docs on Gateway events](https://discordapp.com/developers/docs/topics/gateway#commands-and-events-gateway-events).

  ## Examples

      def handle_event(:READY, data, state) do
        Logger.debug("Connection successful!")
        {:ok, state}
      end
  """
  @callback handle_event(term(), term(), term()) :: {:ok, term()}
end
