defmodule Enmity.User do
  alias Enmity.HTTP
  @moduledoc """
  Documentation for Enmity.
  """

  @doc """
  Gets a user.
  """
  def get(user_id) do
    HTTP.get("/users/#{user_id}") |> HTTP.make_response_nicer()
  end

  def get_me do
    get("@me")
  end

  @doc """
  Modify the current user.

  ## Examples

  Change your username:

      Enmity.User.modify_me(username: "My brand new name")

  Change your avatar:

      Enmity.User.modify_me(avatar: <<...>>)

  You can also change both at the same time.
  This function always returns the updated user object.

  """
  def modify_me(args) do
    args = args
    |> Keyword.take([:username, :avatar])
    |> Map.new()

    args = if Map.has_key?(args, :avatar) do
      Map.update!(args, :avatar, &convert_to_data_uri!/1)
    else
      args
    end

    HTTP.patch("/users/@me", Poison.encode!(args)) |> HTTP.make_response_nicer()
  end

  defp convert_to_data_uri!(image) when is_binary(image) do
    case convert_to_data_uri(image) do
      {:ok, uri} -> uri
      {:error, [invalid_image_type: type]} -> raise "Invalid image type: #{type}"
    end
  end

  defp convert_to_data_uri(image) when is_binary(image) do
    case ExImageInfo.info(image) do
      {"image/jpeg", _, _, _} -> {:ok, "data:image/jpeg;base64,#{Base.encode64(image)}"}
      {"image/png", _, _, _} -> {:ok, "data:image/png;base64,#{Base.encode64(image)}"}
      {"image/gif", _, _, _} -> {:ok, "data:image/gif;base64.,#{Base.encode64(image)}"}
      {type, _, _, _} -> {:error, [invalid_image_type: type]}
    end
  end
end
