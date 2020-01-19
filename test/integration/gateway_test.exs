defmodule Enmity.GatewayTest do
  use ExUnit.Case

  test "connects to the gateway" do
    {:ok, pid} = start_supervised Enmity.Gateway
    Process.sleep(1_000)

    assert Enmity.Gateway.connected?(pid)
  end
end
