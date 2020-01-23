defmodule Enmity.ChannelTest do
  use ExUnit.Case
  alias Enmity.Channel

  test "get" do
    {:ok, channel} = Channel.get("668217932211421242")

    assert channel == %{
      bitrate: 64000,
      guild_id: "668217932211421234",
      id: "668217932211421242",
      name: "General",
      nsfw: false,
      parent_id: "668217932211421238",
      permission_overwrites: [],
      position: 0,
      type: 2,
      user_limit: 0
    }

  end

end
