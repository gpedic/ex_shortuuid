defmodule ShortUUID.Builder do
  @moduledoc """
  ShortUUID is a module for encoding and decoding UUIDs (Universally Unique Identifiers) using various predefined or custom alphabets.

  ## Usage

  To use ShortUUID in your module, simply `use` it and optionally provide an alphabet option:

      defmodule MyModule do
        use ShortUUID.Builder, alphabet: :base58
      end

  The `alphabet` option can be one of the predefined alphabets or a custom string. If no alphabet is provided, the default alphabet (`base57`) will be used.

  ## Predefined Alphabets

  The following predefined alphabets are available:

  - `:base57` - "23456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz" (default)
  - `:base32` - "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
  - `:base32_crockford` - "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
  - `:base32_hex` - "0123456789ABCDEFGHIJKLMNOPQRSTUV"
  - `:base32_rfc4648` - "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
  - `:base32_z` - "ybndrfg8ejkmcpqxot1uwisza345h769"
  - `:base58` - "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
  - `:base62` - "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
  - `:base64` - "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
  - `:base64_url` - "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"

  ## Functions

  The following functions are available for encoding and decoding UUIDs:

  - `encode/1` - Encodes a UUID using the specified or default alphabet.
  - `encode!/1` - Encodes a UUID using the specified or default alphabet, raising an error on failure.
  - `decode/1` - Decodes a string into a UUID using the specified or default alphabet.
  - `decode!/1` - Decodes a string into a UUID using the specified or default alphabet, raising an error on failure.

  ## Example

      iex> ShortUUID.encode("550e8400-e29b-41d4-a716-446655440000")
      {:ok, "H9cNmGXLEc8NWcZzSThA9S"}

      iex> ShortUUID.decode("H9cNmGXLEc8NWcZzSThA9S")
      {:ok, "550e8400-e29b-41d4-a716-446655440000"}
  """

  @predefined_alphabets %{
    base57_shortuuid: "23456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz",
    base32: "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567",
    base32_crockford: "0123456789ABCDEFGHJKMNPQRSTVWXYZ",
    base32_hex: "0123456789ABCDEFGHIJKLMNOPQRSTUV",
    base32_rfc4648: "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567",
    base32_z: "ybndrfg8ejkmcpqxot1uwisza345h769",
    base58: "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz",
    base62: "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz",
    base64: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/",
    base64_url: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
  }

  defmacro __using__(opts) do
    alphabet =
      case Keyword.get(opts, :alphabet) do
        atom when is_atom(atom) -> Map.get(@predefined_alphabets, atom, @predefined_alphabets[:base57_shortuuid])
        binary when is_binary(binary) -> validate_alphabet!(binary)
        other -> validate_alphabet!(other)  # This will raise the appropriate error
      end

    base = String.length(alphabet)
    encoded_length = ceil(:math.log(2 ** 128) / :math.log(base))
    padding_char = String.first(alphabet)

    quote do
      import Bitwise
      alias ShortUUID.Core

      @alphabet unquote(alphabet)
      @padding_char unquote(padding_char)
      @alphabet_tuple @alphabet |> String.graphemes() |> List.to_tuple()
      @codepoint_index String.to_charlist(@alphabet) |> Enum.with_index() |> Map.new()
      @base String.length(@alphabet)
      @encoded_length unquote(encoded_length)

      def encode(uuid), do: Core.encode_binary(uuid, @base, @alphabet_tuple, @encoded_length, @padding_char)

      def encode!(uuid) do
        case encode(uuid) do
          {:ok, encoded} -> encoded
          {:error, msg} -> raise ArgumentError, message: msg
        end
      end

      def decode(string), do: Core.decode_string(string, @base, @codepoint_index, @encoded_length)

      def decode!(string) do
        case decode(string) do
          {:ok, decoded} -> decoded
          {:error, msg} -> raise ArgumentError, message: msg
        end
      end
    end
  end

  defp validate_alphabet!(alphabet) when is_binary(alphabet) do
    graphemes = String.graphemes(alphabet)
    cond do
      length(graphemes) < 16 ->
        raise ArgumentError, message: "Alphabet must contain at least 16 unique characters"
      length(Enum.uniq(graphemes)) != length(graphemes) ->
        raise ArgumentError, message: "Alphabet must not contain duplicate characters"
      true ->
        alphabet
    end
  end

  defp validate_alphabet!(other) do
    raise ArgumentError, message: "Alphabet must be a string, got: #{inspect(other)}"
  end
end
