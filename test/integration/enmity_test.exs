defmodule EnmityTest do
  use ExUnit.Case
  doctest Enmity

  @token Application.fetch_env!(:enmity, :token)

  test "gets a user" do
    {:ok, resp} = Enmity.user("625487844994973716", token: @token)

    assert resp == [
      avatar: nil,
      bot: true,
      discriminator: "4646",
      id: "625487844994973716",
      username: "testbot",
    ]
  end
end
