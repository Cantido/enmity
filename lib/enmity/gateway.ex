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
      use Enmity.Gateway.Websocket
      alias Enmity.Gateway.Websocket
      alias Enmity.Gateway.Operations
      require Logger

      @behaviour Enmity.Gateway

      def connected?(pid) do
        GenServer.call(pid, :is_connected)
      end

      def handle_call(:is_connected, _from, state = %{connected: connected}) do
        {:reply, connected, state}
      end

      def handle_info(:heartbeat, state = %{conn: conn_pid, last_sequence_number: seq, heartbeat_interval_ms: heartbeat_interval_ms}) do
        Logger.debug("Sending heartbeat message")
        Websocket.send(conn_pid, Operations.heartbeat(seq))
        Process.send_after(self(), :heartbeat, heartbeat_interval_ms)
        {:noreply, state}
      end

      def handle_operation(body = %{op: 0, t: event}, state) do
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
      end

      def handle_operation(body = %{op: 10}, state = %{conn: conn_pid}) do
        Logger.debug("Got a hello message, sending identifier frame")
        heartbeat_interval_ms = body.d.heartbeat_interval
        Process.send_after(self(), :heartbeat, heartbeat_interval_ms)

        payload =
          state
          |> Map.get(:last_sequence_number)
          |> Operations.identify()

        Websocket.send(conn_pid, payload)
        {:noreply, Map.put(state, :heartbeat_interval_ms, heartbeat_interval_ms)}
      end

      def handle_operation(body = %{op: 11}, state) do
        {:noreply, state}
      end

      def handle_operation(body, state) do
        Logger.debug("Not a handled operation: #{inspect body}")
        {:noreply, state}
      end

      def handle_event(_, _, state) do
        {:ok, state}
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
end
