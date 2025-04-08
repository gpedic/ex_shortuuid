defmodule ShortUUID.Builder do
  @moduledoc """
  ShortUUID.Builder is a module for encoding and decoding UUIDs (Universally Unique Identifiers) using various predefined or custom alphabets.

  ## Usage

  To create your module, simply `use` it and optionally provide an alphabet option:

      defmodule MyModule do
        use ShortUUID.Builder, alphabet: :base58
      end

  The `alphabet` option must be one of the predefined alphabets or a custom string (16+ unique characters).

  ## Predefined Alphabets

  The following predefined alphabets are available:

  - `:base57_shortuuid` - "23456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
  - `:base32` - "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
  - `:base32_crockford` - "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
  - `:base32_hex` - "0123456789ABCDEFGHIJKLMNOPQRSTUV"
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
    base32_z: "ybndrfg8ejkmcpqxot1uwisza345h769",
    base58: "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz",
    base62: "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz",
    base64: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/",
    base64_url: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
  }

  @max_alphabet_length 256

  defmacro __using__(opts) do
    alphabet_expr = Keyword.fetch!(opts, :alphabet)
    expanded_alphabet = Macro.expand(alphabet_expr, __CALLER__)

    validated_alphabet = validate_alphabet!(expanded_alphabet)
    base = String.length(validated_alphabet)
    encoded_length = ceil(:math.log(2 ** 128) / :math.log(base))
    padding_char = String.first(validated_alphabet)

    quote do
      import Bitwise
      alias ShortUUID.Core
      @behaviour ShortUUID.Behaviour

      @alphabet unquote(validated_alphabet)
      @padding_char unquote(padding_char)
      @alphabet_tuple @alphabet |> String.graphemes() |> List.to_tuple()
      @codepoint_index @alphabet |> String.graphemes() |> Enum.with_index() |> Map.new()
      @base String.length(@alphabet)
      @encoded_length unquote(encoded_length)

      @spec encode(String.t()) :: {:ok, String.t()} | {:error, String.t()}
      def encode(uuid),
        do: Core.encode_binary(uuid, @base, @alphabet_tuple, @encoded_length, @padding_char)

      @spec encode!(String.t()) :: String.t() | no_return()
      def encode!(uuid) do
        case encode(uuid) do
          {:ok, encoded} -> encoded
          {:error, msg} -> raise ArgumentError, message: msg
        end
      end

      @spec decode(String.t()) :: {:ok, String.t()} | {:error, String.t()}
      def decode(string),
        do: Core.decode_string(string, @base, @codepoint_index, @encoded_length)

      @spec decode!(String.t()) :: String.t() | no_return()
      def decode!(string) do
        case decode(string) do
          {:ok, decoded} -> decoded
          {:error, msg} -> raise ArgumentError, message: msg
        end
      end
    end
  end

  defp validate_alphabet!(alphabet) when is_atom(alphabet) do
    predefined = Map.get(@predefined_alphabets, alphabet)

    if is_nil(predefined),
      do: raise(ArgumentError, "Unknown alphabet atom: #{inspect(alphabet)}"),
      else: predefined
  end

  defp validate_alphabet!(alphabet) when is_binary(alphabet) do
    graphemes = String.graphemes(alphabet)

    if length(graphemes) < 16 do
      raise ArgumentError, "Alphabet must contain at least 16 characters"
    end

    if length(graphemes) > @max_alphabet_length do
      raise ArgumentError,
            "Alphabet must not contain more than #{@max_alphabet_length} characters"
    end

    if length(Enum.uniq(graphemes)) != length(graphemes) do
      raise ArgumentError, "Alphabet must not contain duplicate characters"
    end

    alphabet
  end

  defp validate_alphabet!(other) do
    raise ArgumentError,
          "Alphabet must be a literal string or supported atom, got: #{inspect(other)}"
  end
end
