defmodule ShortUUID.Core do
  @moduledoc """
  Core module for ShortUUID encoding and decoding.

  This module provides the core functionality for encoding and decoding UUIDs
  using various alphabets. It includes functions for parsing UUIDs, encoding
  them into shorter strings, and decoding those strings back into UUIDs.

  ## Functions

  - `parse_uuid/1` - Parses a UUID string into a normalized format.
  - `encode_binary/5` - Encodes a UUID into a shorter string using the specified alphabet.
  - `decode_string/4` - Decodes a shortened string back into a UUID.
  - `format_uuid/1` - Formats an integer value as a UUID string.
  - `encode_int/5` - Encodes an integer value into a string using the specified alphabet.
  - `decode_to_int/3` - Decodes a string into an integer value using the specified alphabet.
  - `int_to_string/4` - Converts an integer value into a string using the specified alphabet.
  """

  import Bitwise

  @doc false
  def parse_uuid(
        <<a::binary-size(8), ?-, b::binary-size(4), ?-, c::binary-size(4), ?-, d::binary-size(4),
          ?-, e::binary-size(12)>>
      ) do
    {:ok,
     <<a::binary-size(8), b::binary-size(4), c::binary-size(4), d::binary-size(4),
       e::binary-size(12)>>}
  end

  def parse_uuid(<<_::binary-size(32)>> = uuid), do: {:ok, uuid}

  def parse_uuid(<<?{, uuid::binary-size(36), ?}>>), do: parse_uuid(uuid)
  def parse_uuid(<<?{, uuid::binary-size(32), ?}>>), do: {:ok, uuid}

  def parse_uuid(_), do: {:error, "Invalid UUID"}

  @doc false
  def encode_binary(
        <<a::binary-size(8), ?-, b::binary-size(4), ?-, c::binary-size(4), ?-, d::binary-size(4),
          ?-, e::binary-size(12)>>,
        base,
        alphabet_tuple,
        encoded_length,
        padding
      ) do
    encode_uuid_string(
      <<a::binary-size(8), b::binary-size(4), c::binary-size(4), d::binary-size(4),
        e::binary-size(12)>>,
      base,
      alphabet_tuple,
      encoded_length,
      padding
    )
  end

  def encode_binary(<<_::binary-size(32)>> = uuid, base, alphabet_tuple, encoded_length, padding) do
    encode_uuid_string(uuid, base, alphabet_tuple, encoded_length, padding)
  end

  def encode_binary(
        <<?{, a::binary-size(8), ?-, b::binary-size(4), ?-, c::binary-size(4), ?-,
          d::binary-size(4), ?-, e::binary-size(12), ?}>>,
        base,
        alphabet_tuple,
        encoded_length,
        padding
      ) do
    encode_uuid_string(
      <<a::binary-size(8), b::binary-size(4), c::binary-size(4), d::binary-size(4),
        e::binary-size(12)>>,
      base,
      alphabet_tuple,
      encoded_length,
      padding
    )
  end

  def encode_binary(
        <<?{, uuid::binary-size(32), ?}>>,
        base,
        alphabet_tuple,
        encoded_length,
        padding
      ) do
    encode_uuid_string(<<uuid::binary-size(32)>>, base, alphabet_tuple, encoded_length, padding)
  end

  def encode_binary(_, _, _, _, _), do: {:error, "Invalid UUID"}

  defp encode_uuid_string(uuid, base, alphabet_tuple, encoded_length, padding) do
    case Base.decode16(uuid, case: :mixed) do
      {:ok, decoded_uuid} ->
        encode_int(decoded_uuid, base, alphabet_tuple, encoded_length, padding)

      _ ->
        {:error, "Invalid UUID"}
    end
  end

  @doc false
  def encode_int(<<int_value::128>>, base, alphabet_tuple, encoded_length, padding_char) do
    encoded =
      int_to_string(int_value, base, alphabet_tuple)
      |> pad_string(encoded_length, padding_char)

    if String.length(encoded) == encoded_length do
      {:ok, encoded}
    else
      {:error, "Encoding resulted in incorrect length"}
    end
  end

  defp pad_string(string, length, padding_char) do
    padding_length = length - String.length(string)
    String.duplicate(to_string(padding_char), max(0, padding_length)) <> string
  end

  @doc false
  def decode_string(string, base, codepoint_index, encoded_length) when is_binary(string) do
    with true <- String.length(string) == encoded_length,
         {:ok, value} <- decode_to_int(string, base, codepoint_index),
         true <- value >>> 128 == 0 do
      # Format the UUID after verifying it's within valid range
      {:ok, format_uuid(value)}
    else
      _ -> {:error, "Invalid input"}
    end
  end

  def decode_string(_, _, _, _), do: {:error, "Invalid input"}

  @doc false
  def format_uuid(int_value) when is_integer(int_value) do
    <<int_value::128>>
    |> Base.encode16(case: :lower)
    |> insert_dashes()
  end

  defp insert_dashes(
         <<a::binary-size(8), b::binary-size(4), c::binary-size(4), d::binary-size(4),
           e::binary-size(12)>>
       ) do
    a <> "-" <> b <> "-" <> c <> "-" <> d <> "-" <> e
  end

  defp decode_to_int(string, base, codepoint_index) do
    string
    |> String.graphemes()
    |> Enum.reduce_while({:ok, 0}, fn char, {:ok, acc} ->
      case Map.fetch(codepoint_index, char) do
        {:ok, value} -> {:cont, {:ok, acc * base + value}}
        # Return error instead of continuing
        :error -> {:halt, {:error, "Invalid character"}}
      end
    end)
  end

  defp int_to_string(number, base, alphabet_tuple, acc \\ [])
  defp int_to_string(0, _, _, acc), do: to_string(acc)

  defp int_to_string(number, base, alphabet_tuple, acc) when number > 0 do
    int_to_string(
      div(number, base),
      base,
      alphabet_tuple,
      [elem(alphabet_tuple, rem(number, base)) | acc]
    )
  end
end
