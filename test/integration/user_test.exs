defmodule Enmity.UserTest do
  use ExUnit.Case
  doctest Enmity.User

  test "gets a user" do
    {:ok, resp} = Enmity.User.get("625487844994973716")

    assert resp == [
      avatar: nil,
      bot: true,
      discriminator: "4646",
      id: "625487844994973716",
      username: "Rosa's Robot"
    ]
  end

  test "modifies a user" do
    {:ok, old_me} = Enmity.User.get_me()

    {:ok, new_me} = Enmity.User.modify_me(username: "New test username")

    assert new_me[:username] == "New test username"

    {:ok, _resp} = Enmity.User.modify_me(username: old_me[:username])
  end
end
