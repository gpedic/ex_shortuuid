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
        {:ok, "kGSmvLEEuzjcFZTChXwZpz"}

  The decode/1 function will turn the ShortUUID back into a regular UUID

        iex> ShortUUID.decode("kGSmvLEEuzjcFZTChXwZpz")
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
      "nZJHSqgNVBBSX2h6sRUQuP"

  ## Using ShortUUID with Ecto

  If you want to use ShortUUIDs with Ecto, you can explore the [ecto_shortuuid](https://github.com/gpedic/ecto_shortuuid) library.

  ## Acknowledgments

    This project was inspired by
    [skorokithakis/shortuuid](https://github.com/skorokithakis/shortuuid).
  """
  import Bitwise
  @alphabet "23456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
  @alphabet_tuple @alphabet |> String.graphemes() |> List.to_tuple()
  @codepoint_index String.to_charlist(@alphabet) |> Enum.with_index()

  @doc """
  Encodes a UUID into a ShortUUID string.
  """
  @spec encode(binary) :: {:ok, String.t()} | {:error, String.t()}
  def encode(uuid)

  def encode(
        <<a::binary-size(8), ?-, b::binary-size(4), ?-, c::binary-size(4), ?-, d::binary-size(4),
          ?-, e::binary-size(12)>>
      ) do
    encode_uuid_string(
      <<a::binary-size(8), b::binary-size(4), c::binary-size(4), d::binary-size(4),
        e::binary-size(12)>>
    )
  end

  def encode(<<_::binary-size(32)>> = uuid) do
    encode_uuid_string(uuid)
  end

  def encode(
        <<?{, a::binary-size(8), ?-, b::binary-size(4), ?-, c::binary-size(4), ?-,
          d::binary-size(4), ?-, e::binary-size(12), ?}>>
      ) do
    encode_uuid_string(
      <<a::binary-size(8), b::binary-size(4), c::binary-size(4), d::binary-size(4),
        e::binary-size(12)>>
    )
  end

  def encode(<<?{, uuid::binary-size(32), ?}>>) do
    encode_uuid_string(<<uuid::binary-size(32)>>)
  end

  def encode(<<int_value::128>> = uuid) when is_binary(uuid) do
    uuid = int_to_string(int_value) |> pad_shortuuid()

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
  @spec decode(String.t(), keyword()) :: {:ok, String.t()} | {:error, String.t()}
  def decode(shortuuid, opts \\ [legacy: false])

  def decode(
        <<c1::8, c2::8, c3::8, c4::8, c5::8, c6::8, c7::8, c8::8, c9::8, c10::8, c11::8, c12::8,
          c13::8, c14::8, c15::8, c16::8, c17::8, c18::8, c19::8, c20::8, c21::8, c22::8>>,
        legacy: false
      ) do
    uuid_int_value =
      [
        c1,
        c2,
        c3,
        c4,
        c5,
        c6,
        c7,
        c8,
        c9,
        c10,
        c11,
        c12,
        c13,
        c14,
        c15,
        c16,
        c17,
        c18,
        c19,
        c20,
        c21,
        c22
      ]
      |> Enum.reduce(0, fn char, acc ->
        acc * 57 + char_to_index(char)
      end)

    # verify our int value is <= 128 bits
    # shift it right 128 bits, the result must be 0
    case uuid_int_value >>> 128 do
      0 ->
        uuid =
          <<uuid_int_value::128>>
          |> Base.encode16(case: :lower)
          |> format_uuid()

        {:ok, uuid}

      _ ->
        {:error, "Invalid input"}
    end
  rescue
    _ ->
      {:error, "Invalid input"}
  end

  def decode(
        <<c1::8, c2::8, c3::8, c4::8, c5::8, c6::8, c7::8, c8::8, c9::8, c10::8, c11::8, c12::8,
          c13::8, c14::8, c15::8, c16::8, c17::8, c18::8, c19::8, c20::8, c21::8, c22::8>>,
        legacy: true
      ) do
    decode(
      <<c22, c21, c20, c19, c18, c17, c16, c15, c14, c13, c12, c11, c10, c9, c8, c7, c6, c5, c4,
        c3, c2, c1>>,
      legacy: false
    )
  end

  def decode(_string, _opts) do
    {:error, "Invalid input"}
  end

  @doc """
  Decodes a ShortUUID string into a UUID.

  Raises an ArgumentError if the ShortUUID is invalid.
  """
  @spec decode!(String.t(), keyword()) :: String.t() | no_return()
  def decode!(string, opts \\ [legacy: false]) do
    case decode(string, opts) do
      {:ok, uuid} -> uuid
      {:error, message} -> raise ArgumentError, message: message
    end
  end

  ## Helper functions
  #
  # These helper functions are utilized to process UUIDs into their desired form:

  # - `format_uuid/1`: Formats a UUID into a standard string form.
  # - `int_to_string/2`: Converts a given integer to a string, according to the predefined alphabet.
  # - `pad_shortuuid/2`: Pads the given short UUID with the first character of the alphabet until its size reaches 22.
  # - `char_to_index/1`: Retrieves the index of a given character in the alphabet.

  defp encode_uuid_string(uuid) do
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
  defp int_to_string(number, acc \\ [])
  defp int_to_string(0, acc), do: acc |> to_string

  defp int_to_string(number, acc) when number > 0 do
    int_to_string(div(number, 57), [elem(@alphabet_tuple, rem(number, 57)) | acc])
  end

  # Pads the given short UUID with the first character of the alphabet until its size reaches 22, 176 bits.
  defp pad_shortuuid(<<_::176>> = shortuuid), do: shortuuid

  defp pad_shortuuid(shortuuid),
    do: pad_shortuuid(<<50>> <> shortuuid)

  # Retrieves the index of a given character in the alphabet.
  # This function is generated for each character in the alphabet for quick access.
  @compile {:inline, char_to_index: 1}
  for {char, i} <- @codepoint_index do
    defp char_to_index(unquote(char)), do: unquote(i)
  end

  defp char_to_index(_), do: raise(ArgumentError)
end
