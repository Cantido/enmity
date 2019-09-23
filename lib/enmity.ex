defmodule Enmity do
  @moduledoc """
  Documentation for Enmity.
  """

  @doc """
  Gets a user.
  """
  def user(user_id, [token: token]) do
    url = "https://discordapp.com/api/users/#{user_id}"
    headers = ["Authorization": "Bot #{token}", "Accept": "Application/json; Charset=utf-8"]
    options = [ssl: [{:versions, [:'tlsv1.2']}], recv_timeout: 1_000]

    case HTTPoison.get(url, headers, options) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, Poison.decode!(body)}
      {:ok, %HTTPoison.Response{status_code: code, body: body}} ->
        {:error, [status_code: code, reason: body]}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, [reason: reason]}
    end
  end
end
