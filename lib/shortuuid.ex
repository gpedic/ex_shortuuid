defmodule ShortUUID do
  @moduledoc """

  ShortUUID - generate concise, unambiguous, URL-safe UUIDs

  ## Installation

  Add ShortUUID to your list of dependencies in `mix.exs`:

      def deps do
        [{:shortuuid, "~> #{ShortUUID.Mixfile.project()[:version] |> String.slice(0,3)}"}]
      end


  `encode/1` will translate UUIDs to base57 using lowercase and uppercase letters
  and digits while avoiding similar-looking characters such as l, 1, I, O and 0.

  ## Typical usage

  ShortUUID strives to do one thing well, encode UUIDs. To generate the UUIDs
  use any UUID library you like. Some of options out there are
  [Ecto](https://hexdocs.pm/ecto/Ecto.UUID.html),
  [Elixir UUID](https://github.com/zyro/elixir-uuid) and [Erlang UUID](https://github.com/okeuday/uuid).

  ## Notes

  The output is padded to a length of 22 with the first character of the alphabet (2).

      iex> ShortUUID.encode!("00000000-0000-0000-0000-000000000000")
      "2222222222222222222222"


      iex> ShortUUID.encode!("00000001-0001-0001-0001-000000000001")
      "UD6ibhr3V4YXvriP822222"


      iex> ShortUUID.decode!("UD6ibhr3V4YXvriP822222")
      "00000001-0001-0001-0001-000000000001"

  The input format is quite flexible as any non base16 chars are stripped from the input
  which is then downcased, however only the following formats are covered by tests thus
  guaranteed to work.

  * `2a162ee5-02f4-4701-9e87-72762cbce5e2`
  * `2a162ee502f447019e8772762cbce5e2`
  * `{2a162ee5-02f4-4701-9e87-72762cbce5e2}`
  * `{2a162ee502f447019e8772762cbce5e2}`

  Letter case is not relevant.

  ## Using ShortUUID with Ecto

  If you would like to use ShortUUIDs with Ecto check out [ecto_shortuuid](https://github.com/gpedic/ecto_shortuuid).

  ## Acknowledgments
    This project was inspired by [skorokithakis/shortuuid](https://github.com/skorokithakis/shortuuid).
  """

  @alphabet "23456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
  @alphabet_tuple @alphabet
                  |> String.split("", trim: true)
                  |> List.to_tuple()
  @char_to_int_map @alphabet
                   |> String.split("", trim: true)
                   |> Enum.with_index()
                   |> Enum.reduce(%{}, fn {char, idx}, acc -> Map.put_new(acc, char, idx) end)

  @alphabet_length 57
  @padding_length 22
  @padding_char "2"
  @only_alphabet ~r/^[#{@alphabet}]*$/

  @doc """
  Encode a UUID to ShortUUID.

  ## Examples

      iex> ShortUUID.encode("2a162ee5-02f4-4701-9e87-72762cbce5e2")
      {:ok, "keATfB8JP2ggT7U9JZrpV9"}

  """
  @spec encode!(binary) :: {:ok, String.t()} | {:error, String.t()}
  def encode(<<uuid::128>>) do
    {:ok, uuid |> int_to_string |> pad_shortuuid}
  end

  def encode(uuid) when is_binary(uuid) do
    stripped_uuid = strip_uuid(uuid)

    case stripped_uuid |> String.length() == 32 do
      true ->
        encoded_uuid =
          stripped_uuid
          |> String.to_integer(16)
          |> int_to_string
          |> pad_shortuuid

        {:ok, encoded_uuid}

      _anything_else ->
        {:error, "Invalid UUID"}
    end
  end

  def encode(_), do: {:error, "Invalid UUID"}

  @doc """
  Encode a UUID to ShortUUID.

  Similar to `encode/1` but raises an ArgumentError if it cannot process the UUID.

  ## Examples

      iex> ShortUUID.encode!("2a162ee5-02f4-4701-9e87-72762cbce5e2")
      "keATfB8JP2ggT7U9JZrpV9"

  """
  @spec encode!(binary) :: String.t()
  def encode!(uuid) do
    case encode(uuid) do
      {:ok, encoded_uuid} ->
        encoded_uuid

      {:error, msg} ->
        raise ArgumentError, message: msg
    end
  end

  @doc """
  Decode a ShortUUID.

  ## Examples

      iex> ShortUUID.decode("keATfB8JP2ggT7U9JZrpV9")
      {:ok, "2a162ee5-02f4-4701-9e87-72762cbce5e2"}

  """
  @spec decode(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def decode(string) when is_binary(string) do
    case string |> matches_alphabet? do
      true ->
        string_to_int(string)
        |> int_to_hex_string
        |> pad_uuid
        |> format_uuid_string

      false ->
        {:error, "Invalid input"}
    end
  end

  def decode(_), do: {:error, "Invalid input"}

  @doc """
  Decode a ShortUUID.

  Similar to `decode/1` but raises an ArgumentError if the encoded UUID is invalid.

  ## Examples

      iex> ShortUUID.decode!("keATfB8JP2ggT7U9JZrpV9")
      "2a162ee5-02f4-4701-9e87-72762cbce5e2"
  """
  @spec decode!(String.t()) :: String.t()
  def decode!(string) do
    case decode(string) do
      {:ok, uuid} -> uuid
      {:error, message} -> raise ArgumentError, message: message
    end
  end

  defp int_to_hex_string(number) do
    number
    |> to_hex_string
    |> String.downcase()
  end

  @spec divmod(Integer.t(), Integer.t()) :: [Integer.t()]
  defp divmod(dividend, divisor) do
    [div(dividend, divisor), rem(dividend, divisor)]
  end

  @spec int_to_string(Integer.t(), list()) :: [String.t()]
  defp int_to_string(number, acc \\ [])

  defp int_to_string(number, acc) when number > 0 do
    [result, remainder] = divmod(number, @alphabet_length)
    int_to_string(result, [acc | elem(@alphabet_tuple, remainder)])
  end

  defp int_to_string(0, acc), do: acc |> to_string

  defp strip_uuid(uuid) do
    uuid
    |> String.downcase()
    |> String.replace(~r/[^0-9a-f]/, "")
  end

  defp matches_alphabet?(string) do
    Regex.match?(@only_alphabet, string)
  end

  defp string_to_int(string) do
    string
    |> String.split("", trim: true)
    |> Enum.reverse()
    |> Enum.reduce(0, fn char, acc ->
      %{^char => index} = @char_to_int_map
      acc * @alphabet_length + index
    end)
  end

  defp to_hex_string(number) do
    number |> Integer.to_string(16)
  end

  defp pad_shortuuid(encoded_uuid) do
    encoded_uuid
    |> String.pad_trailing(@padding_length, @padding_char)
  end

  defp pad_uuid(string) do
    string |> String.pad_leading(32, "0")
  end

  defp format_uuid_string(<<u0::64, u1::32, u2::32, u3::32, u4::96>>) do
    {:ok, <<u0::64, ?-, u1::32, ?-, u2::32, ?-, u3::32, ?-, u4::96>>}
  end

  defp format_uuid_string(_invalid), do: {:error, "Invalid UUID"}
end
