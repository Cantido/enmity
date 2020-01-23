defmodule Enmity.Gateway do
  @moduledoc """
  Connects to the Discord Gateway.

  Import this module with `use` and define `handle_event/3` callbacks to receive events from Discord.

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

  Event names are tokens in all-caps.
  See [Discord's full list of events](https://discordapp.com/developers/docs/topics/gateway#commands-and-events).
  """


  defmacro __using__(_opts) do
    quote do
      use GenServer
      alias Enmity.Gateway.Operations
      alias Enmity.Gateway
      require Logger

      def start_link(_args) do
        GenServer.start_link(__MODULE__, :ok)
      end

      def connected?(pid) do
        GenServer.call(pid, :is_connected)
      end

      def init(:ok) do
        {:ok, %{
          connected: false,
          last_sequence_number: nil,
          user_state: %{}
        }, 0}
      end

      def handle_call(:is_connected, _from, state = %{connected: connected}) do
        {:reply, connected, state}
      end

      def handle_info(:timeout, state) do
        {:ok, %{url: url}} = Enmity.HTTP.get("/gateway/bot")
        parsed_url = URI.parse(url)
        {:ok, conn_pid} = :gun.open(to_charlist(parsed_url.host), 443, %{protocols: [:http]})
        {:ok, :http} = :gun.await_up(conn_pid)

        stream_ref = :gun.ws_upgrade(
          conn_pid,
          '/?encoding=etf&v=6')

        state = state
        |> Map.put(:conn, conn_pid)
        |> Map.put(:stream_ref, stream_ref)

        {:noreply, state}
      end

      def handle_info(:heartbeat, state = %{conn: conn_pid, last_sequence_number: seq, heartbeat_interval_ms: heartbeat_interval_ms}) do
        Logger.debug("Sending heartbeat message")
        Gateway.send(conn_pid, Operations.heartbeat(seq))
        Process.send_after(self(), :heartbeat, heartbeat_interval_ms)
        {:noreply, state}
      end

      def handle_info({:gun_ws, _ConnPid, _StreamRef, {:binary, frame}}, state) do
        body = Gateway.decode_frame(frame)

        Logger.debug("Recieved websocket message #{inspect body}")

        handle_operation(body, state)
      end

      def handle_info({:gun_upgrade, _conn_pid, _stream_ref, _, _}, state) do
        Logger.debug("Successfully upgraded to a websocket connection")
        {:noreply, state}
      end

      def handle_info(msg, state) do
        Logger.debug("Got an unrecognized message: #{inspect msg}")
        {:noreply, state}
      end

      def handle_event(_, _, state) do
        {:ok, state}
      end

      def terminate(reason, state) do
        if Map.has_key?(state, :conn_pid) do
          :gun.shutdown(state.conn_pid)
        end
      end

      def handle_operation(body, state = %{conn: conn_pid}) do
        case body.op do
          # regular message dispatch
          0 ->
            event = body.t

            state = if event == :READY do
              Logger.debug("Successfully set up a connection!")
              %{state | connected: true}
            else
              state
            end

            handle_event(event, body.d, state.user_state)
            |> case do
              {:ok, new_user_state} -> {:noreply, %{state | user_state: new_user_state, last_sequence_number: body.s}}
              {:error, reason} -> {:stop, reason, state}
            end

          # hello message
          10 ->
            Logger.debug("Got a hello message, sending identifier frame")
            heartbeat_interval_ms = body.d.heartbeat_interval
            Process.send_after(self(), :heartbeat, heartbeat_interval_ms)

            payload =
              state
              |> Map.get(:last_sequence_number)
              |> Operations.identify()

            Gateway.send(conn_pid, payload)
            {:noreply, Map.put(state, :heartbeat_interval_ms, heartbeat_interval_ms)}
          # heartbeat ack
          11 ->
            {:noreply, state}
          _ ->
            {:noreply, state}
        end
      end
    end
  end

  @doc """
  Handle a Discord Gateway event.

  Event names are tokens in all-caps, like `:READY`.

  Return an `{:ok, state}` tuple on success.
  If you return an `{:error, reason}` tuple, the process will terminate with your given reason.

  For a full list of events, see [Discord's docs on Gateway events](https://discordapp.com/developers/docs/topics/gateway#commands-and-events-gateway-events).

  ## Examples

      def handle_event(:READY, data, state) do
        Logger.debug("Connection successful!")
        {:ok, state}
      end
  """
  @callback handle_event(term(), term(), term()) :: {:ok, term()}

  def decode_frame(frame) do
    frame
    |> :erlang.iolist_to_binary()
    |> :erlang.binary_to_term()
  end

  def send(conn_pid, payload) do
    payload = :erlang.term_to_binary(payload)
    :gun.ws_send(conn_pid, {:binary, payload})
  end
end
