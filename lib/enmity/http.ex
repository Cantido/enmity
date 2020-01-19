defmodule Enmity.HTTP do
  use HTTPoison.Base

  @expected_fields ~w(
    avatar bot discriminator email flags id locale mfa_enabled username verified premium_type system
  )

  @doc """
  Scopes a URL into a Discord bot request.

  ## Examples

      iex> Enmity.HTTP.process_request_url("/users/@me")
      "https://discordapp.com/api/users/@me"

  """
  def process_request_url(url) do
    "https://discordapp.com/api" <> url
  end

  @doc """
  Adds headers to Discord API requests.

  ## Examples

      iex> Enmity.HTTP.process_request_headers([])
      ["Accept": "Application/json; Charset=utf-8"]

  """
  def process_request_headers(headers) do
    headers ++ [
      "Authorization": "Bot #{Application.fetch_env!(:enmity, :token)}",
      "Accept": "Application/json; Charset=utf-8"
    ]
  end

  @doc """
  Adds request options to Discord API requests.

  ## Examples

      iex> Enmity.HTTP.process_request_options([])
      [ssl: [{:versions, [:'tlsv1.2']}], recv_timeout: 1_000]

  """
  def process_request_options(options) do
    options ++ [ssl: [{:versions, [:'tlsv1.2']}], recv_timeout: 1_000]
  end

  @doc """
  Processes a Discord API response body.

  ## Examples

      iex> Enmity.HTTP.process_response_body(~s({"username": "testbot"}))
      [username: "testbot"]

  """
  def process_response_body(body) do
    body
    |> Poison.decode!
    |> Map.take(@expected_fields)
    |> Enum.map(fn({k, v}) -> {String.to_atom(k), v} end)
  end

  def make_response_nicer(response) do
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
