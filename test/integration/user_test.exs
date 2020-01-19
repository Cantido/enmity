defmodule Enmity.UserTest do
  use ExUnit.Case
  doctest Enmity.User

  @token Application.fetch_env!(:enmity, :token)

  test "gets a user" do
    {:ok, resp} = Enmity.User.get("625487844994973716", token: @token)

    assert resp == [
      avatar: nil,
      bot: true,
      discriminator: "4646",
      id: "625487844994973716",
      username: "testbot"
    ]
  end
end
