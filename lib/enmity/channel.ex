defmodule Enmity.Channel do
  alias Enmity.HTTP

  @moduledoc """
  Modify channels and messages.

  See [Discord's channel documentation](https://discordapp.com/developers/docs/resources/channel)
  for more information on each endpoint.
  """

  def get(channel_id) do
    HTTP.get("/channels/#{channel_id}")
  end

  def modify(channel_id, opts) do
    opts = opts
    |> Keyword.take(~w(name position topic nsfw rate_limit_per_user bitrate user_limit permission_overwrites parent_id))
    |> Map.new()
    |> Poison.encode!()

    HTTP.patch("/channels/#{channel_id}", opts)
  end

  def delete(channel_id) do
    HTTP.delete("/channels/#{channel_id}")
  end

  def get_messages(channel_id) do
    HTTP.get("/channels/#{channel_id}/messages")
  end

  def get_message(channel_id, message_id) do
    HTTP.get("/channels/#{channel_id}/messages/#{message_id}")
  end

  def create_message(channel_id, content, opts \\ []) do
    payload = opts
    |> Keyword.take(~w(tts, embed, file, payload_json))
    |> Map.new()
    |> Map.put(:content, content)
    |> Map.put(:nonce, :rand.uniform(65_535))
    |> Poison.encode!()

    HTTP.post("/channels/#{channel_id}/messages", payload)
  end

  def react(channel_id, message_id, emoji) do
    HTTP.put("/channels/#{channel_id}/messages/#{message_id}/reactions/#{emoji}/@me")
  end

  def get_reactions(channel_id, message_id, emoji) do
    HTTP.get("/channels/#{channel_id}/messages/#{message_id}/reactions/#{emoji}")
  end

  def delete_all_reactions(channel_id, message_id) do
    HTTP.delete("/channels/#{channel_id}/messages/#{message_id}/reactions")
  end

  def edit_message(channel_id, message_id, opts) do
    payload = opts
    |> Keyword.take(~w(content embed flags))
    |> Map.new()
    |> Poison.encode!()

    HTTP.patch("/channels/#{channel_id}/messages/#{message_id}", payload)
  end

  def delete_message(channel_id, message_id) do
    HTTP.delete("/channels/#{channel_id}/messages/#{message_id}")
  end

  def bulk_delete_messages(channel_id, message_ids) when is_list(message_ids) do
    payload = Poison.encode!(message_ids)
    HTTP.post("/channels/#{channel_id}/messages/bulk-delete", payload)
  end

  def edit_permissions(channel_id, overwrite_id, opts) do
    payload = opts
    |> Keyword.take(~w(allow deny type))
    |> Map.new()
    |> Poison.encode!()

    HTTP.put("/channels/#{channel_id}/permissions/#{overwrite_id}", payload)
  end

  def get_invites(channel_id) do
    HTTP.get("/channels/#{channel_id}/invites")
  end

  def create_invite(channel_id, opts \\ []) do
    payload = opts
    |> Keyword.take(~w(max_age max_uses temporary unique))
    |> Map.new()
    |> Poison.encode!()

    HTTP.post("/channel/#{channel_id}/invites", payload)
  end

  def delete_permission(channel_id, overwrite_id) do
    HTTP.delete("/channels/#{channel_id}/permissions/#{overwrite_id}")
  end

  def trigger_typing_indicator(channel_id) do
    HTTP.post("/channels/#{channel_id}/typing", "{}")
  end

  def get_pinned_messages(channel_id) do
    HTTP.get("/channels/#{channel_id}/pinned")
  end

  def add_pinned_message(channel_id, message_id) do
    HTTP.put("/channels/#{channel_id}/pins/#{message_id}")
  end

  def delete_pinned_message(channel_id, message_id) do
    HTTP.delete("/channels/#{channel_id}/pins/#{message_id}")
  end

  def group_dm_add_recipient(channel_id, user_id, access_token, nick) do
    payload = %{
      access_token: access_token,
      nick: nick
    } |> Poison.encode!()

    HTTP.put("/channels/#{channel_id}/recipients/#{user_id}", payload)
  end

  def group_dm_remove_recipient(channel_id, user_id) do
    HTTP.delete("/channels/#{channel_id}/recipients/#{user_id}")
  end
end
