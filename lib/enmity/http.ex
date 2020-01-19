defmodule Enmity.HTTP do
  use HTTPoison.Base
  require Logger

  @user_fields ~w(
    avatar bot discriminator email flags id locale mfa_enabled username
    verified premium_type system
  )

  @guild_fields ~w(
    name icon owner permissions
  )

  @channel_fields ~w(
    id type guild_id position permission_overwrites name topic nsfw
    last_message_id bitrate user_limit rate_limit_per_user recipients
    icon owner_id application_id parent_id last_pin_timestamp
  )

  @gateway_fields ~w(
    url shards session_start_limit total remaining reset_after
  )

  @expected_fields @user_fields ++ @guild_fields ++ @channel_fields ++ @gateway_fields

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
      [
        "Authorization": "Bot A gigantic fifty-nine character string 12345678901234567890",
        "Accept": "Application/json; Charset=utf-8",
        "Content-Type": "application/json"
      ]
  """
  def process_request_headers(headers) do
    headers ++ [
      "Authorization": "Bot #{Application.fetch_env!(:enmity, :token)}",
      "Accept": "Application/json; Charset=utf-8",
      "Content-Type": "application/json"
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
      %{username: "testbot"}

  """
  def process_response_body(body) do
    Logger.debug("Response body: #{body}")
    body = Poison.decode!(body)

    if is_list(body) do
      Enum.map(body, &sanitize_keys/1)
    else
      sanitize_keys(body)
      |> update_if_present("session_start_limit", &sanitize_keys/1)
    end
  end

  defp update_if_present(map, key, fun) when is_map(map) and is_function(fun) do
    if Map.has_key?(map, key) do
      Map.update!(map, key, fun)
    else
      map
    end
  end

  defp sanitize_keys(map) when is_map(map) do
    map
    |> Map.take(@expected_fields)
    |> Enum.map(fn({k, v}) -> {String.to_atom(k), v} end)
    |> Map.new()
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
