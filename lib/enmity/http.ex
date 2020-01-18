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
     headers ++ ["Accept": "Application/json; Charset=utf-8"]
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

#  "{\"username\": \"testbot\", \"verified\": true, \"locale\": \"en-US\", \"mfa_enabled\": true, \"bot\": true, \"id\": \"625487844994973716\", \"flags\": 0, \"avatar\": null, \"discriminator\": \"4646\", \"email\": null}"
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
end
