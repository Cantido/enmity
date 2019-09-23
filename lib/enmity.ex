defmodule Enmity do
  @moduledoc """
  Documentation for Enmity.
  """

  @doc """
  Gets a user.
  """
  def user(user_id, [token: token]) do
    url = "/users/#{user_id}"
    headers = ["Authorization": "Bot #{token}"]

    Enmity.HTTP.get(url, headers) |> make_response_nicer()
  end

  defp make_response_nicer(response) do
    case response do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body}
      {:ok, %HTTPoison.Response{status_code: code, body: body}} ->
        {:error, [status_code: code, reason: body]}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, [reason: reason]}
    end
  end
end
