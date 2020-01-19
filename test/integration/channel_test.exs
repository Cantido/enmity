defmodule Enmity.ChannelTest do
  use ExUnit.Case
  alias Enmity.Channel

  test "get" do
    {:ok, channel} = Channel.get(668_217_932_211_421_242)

    assert channel == "hi :)"
  end

end
