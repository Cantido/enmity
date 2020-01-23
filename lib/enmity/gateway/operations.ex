defmodule Enmity.Gateway.Operations do
  def heartbeat(last_sequence_number) do
    %{
      "op" => 1,
      "t" => "HEARTBEAT",
      "d" => last_sequence_number
    }
  end

  def identify(last_sequence_number) do
    {osfamily, osname} = :os.type()
    osname = "#{osfamily} #{to_string(osname)}"

    %{
      "op" => 2,
      "t" => "IDENTIFY",
      "s" => last_sequence_number,
      "d" => %{
        "token" => Application.fetch_env!(:enmity, :token),
        "properties" => %{
          "$os" => osname,
          "$browser" => "enmity",
          "$device" => "enmity"
        }
      }
    }
  end
end
