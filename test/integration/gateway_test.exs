defmodule Enmity.GatewayTest do
  use ExUnit.Case

  test "connects to the gateway" do
    {:ok, pid} = start_supervised Enmity.Testbot
    Process.sleep(1_000)

    assert Enmity.Testbot.connected?(pid)
  end
end
