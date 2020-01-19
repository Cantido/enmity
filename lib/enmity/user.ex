defmodule Enmity.User do
  @moduledoc """
  Documentation for Enmity.
  """

  @doc """
  Gets a user.
  """
  def get(user_id) do
    Enmity.HTTP.get("/users/#{user_id}") |> Enmity.HTTP.make_response_nicer()
  end
end
