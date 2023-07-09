defmodule ShortUUID do
  @moduledoc """
  ShortUUID - generate concise, unambiguous, URL-safe UUIDs.

  ## Installation

  Add ShortUUID to your list of dependencies in `mix.exs`:

      def deps do
        [
          {:shortuuid, "~> #{ShortUUID.Mixfile.project()[:version] |> String.slice(0, 3)}"}
        ]
      end

  ## Usage

  The encode/1 function translates UUIDs to base57 using lowercase and uppercase letters, as well as digits,
  while ensuring that similar-looking characters such as 'l', '1', 'I', 'O', and '0' are avoided.

        iex> ShortUUID.encode("ed7ba470-8e54-465e-825c-99712043e01c")
        {:ok, "zpZwXhCTZFcjzuEELvmSGk"}

  The decode/1 function will turn the ShortUUID back into a regular UUID

        iex> ShortUUID.decode("zpZwXhCTZFcjzuEELvmSGk")
        {:ok, "ed7ba470-8e54-465e-825c-99712043e01c"}


  ShortUUID strives to do one thing well, encode UUIDs. To generate UUIDs use any UUID library of your choice.

  Some options:
  [Ecto](https://hexdocs.pm/ecto/Ecto.UUID.html)
  [Elixir UUID](https://github.com/zyro/elixir-uuid)
  [Erlang UUID](https://github.com/okeuday/uuid)


  ## Notes

  ShortUUID supports the following input formats:

  * `2a162ee5-02f4-4701-9e87-72762cbce5e2`
  * `2a162ee502f447019e8772762cbce5e2`

  Letter case is not relevant.

  Since version v2.1.0, ShortUUID also supports the encoding of binary UUIDs.

      iex> ShortUUID.encode!(<<0xFA, 0x62, 0xAF, 0x80, 0xA8, 0x61, 0x45, 0x6C, 0xAB, 0x77, 0xD5, 0x67, 0x7E, 0x2E, 0x8B, 0xA8>>)
      "PuQURs6h2XSBBVNgqSHJZn"

  ## Using ShortUUID with Ecto

  If you want to use ShortUUIDs with Ecto, you can explore the [ecto_shortuuid](https://github.com/gpedic/ecto_shortuuid) library.

  ## Acknowledgments

    This project was inspired by
    [skorokithakis/shortuuid](https://github.com/skorokithakis/shortuuid).
  """
  use Bitwise, only_operators: true
  @alphabet "23456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
  @alphabet_tuple @alphabet |> String.split("", trim: true) |> List.to_tuple()
  @alphabet_list String.graphemes(@alphabet) |> Enum.with_index()

  @doc """
  Encodes a UUID into a ShortUUID string.
  """
  @spec encode(binary) :: {:ok, String.t()} | {:error, String.t()}
  def encode(
        <<a::binary-size(8), ?-, b::binary-size(4), ?-, c::binary-size(4), ?-, d::binary-size(4),
          ?-, e::binary-size(12)>>
      ) do
    decode_uuid(
      <<a::binary-size(8), b::binary-size(4), c::binary-size(4), d::binary-size(4),
        e::binary-size(12)>>
    )
  end

  def encode(<<_::binary-size(32)>> = uuid) do
    decode_uuid(uuid)
  end

  def encode(
        <<?{, a::binary-size(8), ?-, b::binary-size(4), ?-, c::binary-size(4), ?-,
          d::binary-size(4), ?-, e::binary-size(12), ?}>>
      ) do
    decode_uuid(
      <<a::binary-size(8), b::binary-size(4), c::binary-size(4), d::binary-size(4),
        e::binary-size(12)>>
    )
  end

  def encode(<<?{, uuid::binary-size(32), ?}>>) do
    decode_uuid(<<uuid::binary-size(32)>>)
  end

  def encode(<<int_value::128>> = uuid) when is_binary(uuid) do
    uuid =
      int_value
      |> int_to_string()
      |> pad_shortuuid()

    {:ok, uuid}
  end

  def encode(_), do: {:error, "Invalid UUID"}

  @doc """
  Encodes a UUID into a ShortUUID string.

  Raises an ArgumentError if the UUID is invalid.
  """
  @spec encode!(binary) :: String.t() | no_return()
  def encode!(uuid) do
    case encode(uuid) do
      {:ok, encoded_uuid} ->
        encoded_uuid

      {:error, msg} ->
        raise ArgumentError, message: msg
    end
  end

  @doc """
  Decodes a ShortUUID string into a UUID.
  """
  @spec decode(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def decode(shortuuid)
      when is_binary(shortuuid) and byte_size(shortuuid) == 22 do
    with {:ok, int_value} <- shortuuid_string_to_int(shortuuid),
         0 <- int_value >>> 128 do
      uuid =
        <<int_value::128>>
        |> Base.encode16(case: :lower)
        |> format_uuid()

      {:ok, uuid}
    else
      _ ->
        {:error, "Invalid input"}
    end
  end

  def decode(_string) do
    {:error, "Invalid input"}
  end

  @doc """
  Decodes a ShortUUID string into a UUID.

  Raises an ArgumentError if the ShortUUID is invalid.
  """
  @spec decode!(String.t()) :: String.t() | no_return()
  def decode!(string) do
    case decode(string) do
      {:ok, uuid} -> uuid
      {:error, message} -> raise ArgumentError, message: message
    end
  end

  ## Helper functions
  #
  # These helper functions are utilized to process UUIDs into their desired form:

  # - `format_uuid/1`: Formats a UUID into a standard string form.
  # - `int_to_string/2`: Converts a given integer to a string, according to the predefined alphabet.
  # - `shortuuid_string_to_int/1`: Converts a short UUID string back into its integer form.
  # - `pad_shortuuid/1`: Pads the given short UUID with the first character of the alphabet until its size reaches 22.
  # - `char_to_index/1`: Retrieves the index of a given character in the alphabet.

  defp decode_uuid(uuid) do
    uuid
    |> Base.decode16(case: :mixed)
    |> case do
      {:ok, decoded_uuid} ->
        encode(decoded_uuid)

      _ ->
        {:error, "Invalid UUID"}
    end
  end

  # Formats a UUID into a standard string form.
  defp format_uuid(
         <<a::binary-size(8), b::binary-size(4), c::binary-size(4), d::binary-size(4),
           e::binary-size(12)>>
       ) do
    a <> "-" <> b <> "-" <> c <> "-" <> d <> "-" <> e
  end

  # Converts a given integer to a string, according to the predefined alphabet.
  # This function uses tail recursion for efficiency and reverses the resulting list at the end for correctness.
  defp int_to_string(number, acc \\ "")
  defp int_to_string(0, acc), do: acc |> to_string

  defp int_to_string(number, acc) when number > 0 do
    int_to_string(div(number, 57), acc <> elem(@alphabet_tuple, rem(number, 57)))
  end

  # Converts a short UUID string back into its integer form.
  # This function uses the `Enum.reduce_while/3` function to halt the process when an invalid character is encountered.
  defp shortuuid_string_to_int(shortuuid_string) do
    shortuuid_string
    |> :binary.bin_to_list()
    |> :lists.reverse()
    |> Enum.reduce_while(0, fn char, acc ->
      case char_to_index(<<char::utf8>>) do
        nil ->
          {:halt, nil}

        i ->
          {:cont, acc * 57 + i}
      end
    end)
    |> case do
      nil -> {:error, :invalid_char}
      value -> {:ok, value}
    end
  end

  # Pads the given short UUID with the first character of the alphabet until its size reaches 22, 176 bits.
  # The padding operation uses a tail-recursive helper function for efficiency.
  defp pad_shortuuid(<<_::176>> = shortuuid), do: shortuuid
  defp pad_shortuuid(shortuuid), do: pad_shortuuid(shortuuid <> <<50>>)

  # Retrieves the index of a given character in the alphabet.
  # This function is generated for each character in the alphabet for quick access.
  @compile {:inline, char_to_index: 1}
  for {char, i} <- @alphabet_list do
    defp char_to_index(unquote(char)), do: unquote(i)
  end

  defp char_to_index(_), do: nil
end
