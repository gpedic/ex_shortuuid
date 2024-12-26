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

  @type uuid_string :: String.t()
  @type normalized_uuid :: String.t()
  @type short_uuid :: String.t()

  @spec parse_uuid(String.t()) :: {:ok, normalized_uuid} | {:error, String.t()}
  @doc """
  Parses and normalizes various UUID string formats.

  ## Examples

      iex> ShortUUID.Core.parse_uuid("550e8400-e29b-41d4-a716-446655440000")
      {:ok, "550e8400e29b41d4a716446655440000"}

      iex> ShortUUID.Core.parse_uuid("{550e8400-e29b-41d4-a716-446655440000}")
      {:ok, "550e8400e29b41d4a716446655440000"}

      iex> ShortUUID.Core.parse_uuid("not-a-uuid")
      {:error, "Invalid UUID"}
  """
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

  @spec encode_binary(uuid_string, pos_integer, tuple, pos_integer, String.t()) ::
          {:ok, short_uuid} | {:error, String.t()}
  @doc """
  Encodes a UUID string into a shorter string using the specified alphabet and base.
  Takes a UUID string, base number, alphabet tuple, desired length, and padding character.

  ## Examples

      iex> alphabet = String.graphemes("123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz") |> List.to_tuple()
      iex> ShortUUID.Core.encode_binary("550e8400-e29b-41d4-a716-446655440000", 58, alphabet, 22, "1")
      {:ok, "BWBeN28Vb7cMEx7Ym8AUzs"}

      iex> alphabet = String.graphemes("123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz") |> List.to_tuple()
      iex> ShortUUID.Core.encode_binary("invalid", 58, alphabet, 22, "1")
      {:error, "Invalid UUID"}
  """
  def encode_binary(input, base, alphabet_tuple, encoded_length, padding) do
    with {:ok, bin_uuid} <- parse_uuid(input),
         {:ok, decoded} <- Base.decode16(bin_uuid, case: :mixed) do
      encode_int(decoded, base, alphabet_tuple, encoded_length, padding)
    else
      _ -> {:error, "Invalid UUID"}
    end
  end

  @spec encode_int(binary, pos_integer, tuple, pos_integer, String.t()) ::
          {:ok, short_uuid} | {:error, String.t()}
  @doc """
  Encodes a 128-bit integer into a string using the specified base and alphabet.
  Pads the result to the desired length using the padding character.
  """
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

  @spec decode_string(String.t(), pos_integer, map, pos_integer) ::
          {:ok, uuid_string} | {:error, String.t()}
  @doc """
  Decodes a shortened string back into a UUID using the specified base and alphabet.
  Validates the input length and ensures the decoded value is within valid UUID range.

  ## Examples

      iex> alphabet = String.graphemes("123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz") |> Enum.with_index() |> Map.new()
      iex> ShortUUID.Core.decode_string("BWBeN28Vb7cMEx7Ym8AUzs", 58, alphabet, 22)
      {:ok, "550e8400-e29b-41d4-a716-446655440000"}

      iex> alphabet = String.graphemes("123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz") |> Enum.with_index() |> Map.new()
      iex> ShortUUID.Core.decode_string("invalid", 58, alphabet, 22)
      {:error, "Invalid input"}
  """
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

  @spec format_uuid(non_neg_integer) :: uuid_string
  @doc """
  Formats a 128-bit integer as a standard UUID string with dashes.
  Converts the integer to a 32-character hex string and inserts dashes in the correct positions.

  ## Examples

      iex> ShortUUID.Core.format_uuid(0x550e8400e29b41d4a716446655440000)
      "550e8400-e29b-41d4-a716-446655440000"
  """
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

  # Decodes a string into its integer representation using the specified base and alphabet.
  # Returns an error if any character in the string is not in the alphabet.
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

  # Converts an integer to a string using the specified base and alphabet.
  # Uses tail recursion with an accumulator for efficiency.
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
