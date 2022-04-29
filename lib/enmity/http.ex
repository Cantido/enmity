defmodule Enmity.HTTP do
  use HTTPoison.Base
  require Logger

  @moduledoc """
  The `HTTPoison.Base` implementation for Discord's HTTP API.
  """

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

  @message_fields ~w(
    id channel_id guild_id author member content timestamp edited_timestamp tts
    mention_everyone mentions mention_roles mention_channels attachments embeds
    reactions nonce pinned webhook_id type activity application
    message_reference flags
  )

  @rate_limited_fields ~w(message retry_after global)

  @expected_fields @user_fields ++ @guild_fields ++ @channel_fields ++
                   @gateway_fields ++ @message_fields ++ @rate_limited_fields

  @doc """
  Scopes a URL into a Discord bot request.

  ## Examples

      Enmity.HTTP.process_request_url("/users/@me")
      "https://discordapp.com/api/users/@me"

  """
  def process_request_url(url) do
    "https://discordapp.com/api" <> url
  end

  @doc """
  Adds headers to Discord API requests.

  ## Examples

      Enmity.HTTP.process_request_headers([])
      [
        "Authorization": "Bot A gigantic fifty-nine character string 12345678901234567890",
        "Accept": "Application/json; Charset=utf-8",
        "Content-Type": "application/json",
        "X-RateLimit-Precision": "second"
      ]
  """
  def process_request_headers(headers) do
    headers ++ [
      "Authorization": "Bot #{Application.fetch_env!(:enmity, :token)}",
      "Accept": "Application/json; Charset=utf-8",
      "Content-Type": "application/json",
      "X-RateLimit-Precision": "second"
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

      Enmity.HTTP.process_response_body(~s({"username": "testbot"}))
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

  def process_response(%HTTPoison.Response{status_code: 200, body: body}) do
    body
  end

  def process_response(%HTTPoison.Error{reason: reason}) do
    reason
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
end
