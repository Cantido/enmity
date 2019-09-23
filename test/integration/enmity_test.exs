defmodule EnmityTest do
  use ExUnit.Case
  doctest Enmity

  @token Application.fetch_env!(:enmity, :token)

  test "gets a user" do
    {:ok, resp} = Enmity.user("@me", token: @token)

    assert resp == %{
      "avatar" => nil,
      "bot" => true,
      "discriminator" => "4646",
      "email" => nil,
      "flags" => 0,
      "id" => "625487844994973716",
      "locale" => "en-US",
      "mfa_enabled" => true,
      "username" => "testbot",
      "verified" => true
    }
  end
end
