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
  - `build_decode_index/1` - Builds the lookup structure used by `decode_string/4`.

  Alphabet symbols are matched by their exact codepoints, not by grapheme
  clusters. Symbols that visually merge when placed next to each other (for
  example combining marks or regional indicators) are therefore handled
  correctly, as long as no symbol is a prefix of another symbol.
  """

  import Bitwise

  @type uuid_string :: String.t()
  @type normalized_uuid :: String.t()
  @type short_uuid :: String.t()
  @opaque decode_index :: {:shortuuid_decode_index, map, pos_integer}

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
    {digits, digit_count} = int_to_digits(int_value, base, alphabet_tuple, [], 0)

    # Length is measured in alphabet symbols, not graphemes: adjacent symbols
    # may render as a single grapheme (e.g. combining marks) without being ambiguous.
    if digit_count <= encoded_length do
      padding = List.duplicate(to_string(padding_char), encoded_length - digit_count)
      {:ok, IO.iodata_to_binary([padding | digits])}
    else
      {:error, "Encoding resulted in incorrect length"}
    end
  end

  @spec build_decode_index([String.t()]) :: decode_index
  @doc """
  Builds the decode index for a list of alphabet symbols, where the position of a
  symbol in the list is its digit value.

  No symbol may be a prefix of another symbol (compared by codepoints), otherwise
  an `ArgumentError` is raised.
  """
  def build_decode_index([_ | _] = symbols) do
    trie =
      symbols
      |> Enum.with_index()
      |> Enum.reduce(%{}, fn {symbol, value}, trie ->
        put_symbol(trie, String.to_charlist(symbol), value, symbol)
      end)

    max_symbol_bytes = symbols |> Enum.map(&byte_size/1) |> Enum.max()
    {:shortuuid_decode_index, trie, max_symbol_bytes}
  end

  defp put_symbol(_trie, [], _value, symbol), do: raise_prefix_error(symbol)

  defp put_symbol(trie, [codepoint], value, symbol) do
    if Map.has_key?(trie, codepoint),
      do: raise_prefix_error(symbol),
      else: Map.put(trie, codepoint, {:value, value})
  end

  defp put_symbol(trie, [codepoint | rest], value, symbol) do
    case Map.get(trie, codepoint, %{}) do
      %{} = subtrie -> Map.put(trie, codepoint, put_symbol(subtrie, rest, value, symbol))
      {:value, _} -> raise_prefix_error(symbol)
    end
  end

  defp raise_prefix_error(symbol) do
    raise ArgumentError,
          "Alphabet symbols must not be empty or a prefix of another symbol, got: #{inspect(symbol)}"
  end

  @spec decode_string(String.t(), pos_integer, decode_index | map, pos_integer) ::
          {:ok, uuid_string} | {:error, String.t()}
  @doc """
  Decodes a shortened string back into a UUID using the specified base and alphabet.
  Validates the input length and ensures the decoded value is within valid UUID range.

  The index should be built with `build_decode_index/1`. A plain map of
  `symbol => value` is also accepted, but is converted on every call.

  ## Examples

      iex> alphabet = String.graphemes("123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz") |> Enum.with_index() |> Map.new()
      iex> ShortUUID.Core.decode_string("BWBeN28Vb7cMEx7Ym8AUzs", 58, alphabet, 22)
      {:ok, "550e8400-e29b-41d4-a716-446655440000"}

      iex> alphabet = String.graphemes("123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz") |> Enum.with_index() |> Map.new()
      iex> ShortUUID.Core.decode_string("invalid", 58, alphabet, 22)
      {:error, "Invalid input"}
  """
  def decode_string(
        string,
        base,
        {:shortuuid_decode_index, trie, max_symbol_bytes},
        encoded_length
      )
      when is_binary(string) do
    with true <- byte_size(string) <= max_symbol_bytes * encoded_length,
         {:ok, value, ^encoded_length} <-
           decode_symbols(string, trie, :root, base, 0, 0, encoded_length),
         true <- value >>> 128 == 0 do
      # Format the UUID after verifying it's within valid range
      {:ok, format_uuid(value)}
    else
      _ -> {:error, "Invalid input"}
    end
  end

  def decode_string(string, base, %{} = symbol_index, encoded_length) when is_binary(string) do
    index =
      symbol_index
      |> Enum.sort_by(fn {_symbol, value} -> value end)
      |> Enum.map(fn {symbol, _value} -> symbol end)
      |> build_decode_index()

    decode_string(string, base, index, encoded_length)
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

  # Walks the input codepoint by codepoint through the symbol trie. Because no
  # symbol is a prefix of another, the first complete match is the only possible
  # one, so every input has at most one parse. Stops as soon as more than
  # `max_count` symbols are seen or a codepoint is not part of any symbol.
  defp decode_symbols(<<>>, _trie, :root, _base, acc, count, _max_count), do: {:ok, acc, count}

  defp decode_symbols(<<codepoint::utf8, rest::binary>>, trie, node, base, acc, count, max_count) do
    current = if node == :root, do: trie, else: node

    case current do
      %{^codepoint => {:value, value}} when count < max_count ->
        decode_symbols(rest, trie, :root, base, acc * base + value, count + 1, max_count)

      %{^codepoint => %{} = next} ->
        decode_symbols(rest, trie, next, base, acc, count, max_count)

      _ ->
        :error
    end
  end

  defp decode_symbols(_string, _trie, _node, _base, _acc, _count, _max_count), do: :error

  # Converts an integer to a list of alphabet symbols (most significant first)
  # and counts them.
  defp int_to_digits(0, _base, _alphabet_tuple, acc, count), do: {acc, count}

  defp int_to_digits(number, base, alphabet_tuple, acc, count) when number > 0 do
    int_to_digits(
      div(number, base),
      base,
      alphabet_tuple,
      [elem(alphabet_tuple, rem(number, base)) | acc],
      count + 1
    )
  end
end
