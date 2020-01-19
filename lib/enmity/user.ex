defmodule Enmity.User do
  @moduledoc """
  Documentation for Enmity.
  """

  @doc """
  Gets a user.
  """
  def get(user_id) do
    token = Application.fetch_env!(:enmity, :token)
    url = "/users/#{user_id}"
    headers = ["Authorization": "Bot #{token}"]

    Enmity.HTTP.get(url, headers) |> Enmity.HTTP.make_response_nicer()
  end
end
