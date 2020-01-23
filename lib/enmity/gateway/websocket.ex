defmodule Enmity.Gateway.Websocket do

  defmacro __using__(_opts) do
    quote do
      use GenServer
      alias Enmity.Gateway.Websocket
      require Logger

      def start_link(_args) do
        GenServer.start_link(__MODULE__, :ok)
      end

      def init(:ok) do
        {:ok, %{
          connected: false,
          last_sequence_number: nil,
          user_state: %{}
        }, 0}
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

      def handle_info({:gun_ws, _ConnPid, _StreamRef, {:binary, frame}}, state) do
        body = Websocket.decode_frame(frame)

        Logger.debug("Recieved websocket message #{inspect body}")

        handle_operation(body, state)
      end

      def handle_info({:gun_upgrade, _conn_pid, _stream_ref, _, _}, state) do
        Logger.debug("Successfully upgraded to a websocket connection")
        {:noreply, state}
      end

      def terminate(reason, state) do
        if Map.has_key?(state, :conn_pid) do
          :gun.shutdown(state.conn_pid)
        end
      end
    end
  end


  @callback handle_operation(term(), term()) :: {:ok, term()}

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
