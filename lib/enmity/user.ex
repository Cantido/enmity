defmodule Enmity.User do
  @moduledoc """
  Documentation for Enmity.
  """

  @doc """
  Gets a user.
  """
  def get(user_id, [token: token]) do
    url = "/users/#{user_id}"
    headers = ["Authorization": "Bot #{token}"]

    Enmity.HTTP.get(url, headers) |> Enmity.HTTP.make_response_nicer()
  end
end
