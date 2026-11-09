defmodule ShortUUID.Builder do
  @moduledoc """
  ShortUUID.Builder is a module for encoding and decoding UUIDs (Universally Unique Identifiers) using various predefined or custom alphabets.

  ## Usage

  To create your module, simply `use` it and optionally provide an alphabet option:

      defmodule MyModule do
        use ShortUUID.Builder, alphabet: :base58
      end

  The `alphabet` option must be one of the predefined alphabets or a custom string
  of 16 to 256 unique characters.

  Alphabets are not required to be URL-safe. Custom alphabets may contain any characters,
  including ones with a special meaning in URLs. All predefined alphabets are URL-safe
  except `:base64`, which uses `+` and `/`; use `:base64_url` if you need URL-safe base64.

  The alphabet is split into characters by grapheme, but encoded strings are matched
  by exact codepoints, so characters that visually merge when concatenated (combining
  marks, regional indicators, emoji modifiers) are supported. No character may be a
  prefix of another one, characters must be in Unicode NFC form, and alphabets that
  could make a Unicode-normalized ID decode to a different UUID are rejected.

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

  import Bitwise

  @max_alphabet_length 256

  defmacro __using__(opts) do
    alphabet_expr = Keyword.fetch!(opts, :alphabet)
    expanded_alphabet = Macro.expand(alphabet_expr, __CALLER__)

    validated_alphabet = validate_alphabet!(expanded_alphabet)
    symbols = String.graphemes(validated_alphabet)
    base = length(symbols)
    encoded_length = encoded_length(base)
    padding_char = hd(symbols)
    alphabet_tuple = List.to_tuple(symbols)
    decode_index = ShortUUID.Core.build_decode_index(symbols)

    escaped_alphabet = Macro.escape(alphabet_tuple)
    escaped_index = Macro.escape(decode_index)
    alphabet_doc = "#{base} characters: `#{inspect(validated_alphabet)}`"

    # Everything is unquoted directly into the function bodies so that `use`
    # does not add aliases, imports or module attributes to the caller.
    quote do
      @behaviour ShortUUID.Behaviour

      @doc """
      Encodes a UUID string into a #{unquote(encoded_length)}-character short ID.

      Accepts UUIDs with or without hyphens, in curly braces or with a `urn:uuid:`
      prefix, in any letter case. The alphabet has #{unquote(alphabet_doc)}.

      Returns `{:ok, short_id}` or `{:error, "Invalid UUID"}`.
      """
      @impl ShortUUID.Behaviour
      @spec encode(String.t()) :: {:ok, String.t()} | {:error, String.t()}
      def encode(uuid) do
        ShortUUID.Core.encode_binary(
          uuid,
          unquote(base),
          unquote(escaped_alphabet),
          unquote(encoded_length),
          unquote(padding_char)
        )
      end

      @doc """
      Encodes a UUID string like `encode/1`, but returns the short ID directly and
      raises an `ArgumentError` on invalid input.
      """
      @impl ShortUUID.Behaviour
      @spec encode!(String.t()) :: String.t() | no_return()
      def encode!(uuid) do
        case encode(uuid) do
          {:ok, encoded} -> encoded
          {:error, msg} -> raise ArgumentError, message: msg
        end
      end

      @doc """
      Decodes a #{unquote(encoded_length)}-character short ID back into a lowercase,
      hyphenated UUID string.

      Short IDs are case-sensitive and must use exactly this module's alphabet
      (#{unquote(alphabet_doc)}). Returns `{:ok, uuid}` or `{:error, "Invalid input"}`.
      """
      @impl ShortUUID.Behaviour
      @spec decode(String.t()) :: {:ok, String.t()} | {:error, String.t()}
      def decode(string) do
        ShortUUID.Core.decode_string(
          string,
          unquote(base),
          unquote(escaped_index),
          unquote(encoded_length)
        )
      end

      @doc """
      Decodes a short ID like `decode/1`, but returns the UUID directly and raises
      an `ArgumentError` on invalid input.
      """
      @impl ShortUUID.Behaviour
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

    validate_prefix_free!(graphemes)

    # ASCII is unaffected by Unicode normalization, so the checks below only
    # matter for alphabets with non-ASCII characters.
    unless ascii?(alphabet), do: validate_normalization_safe!(graphemes)

    alphabet
  end

  defp validate_alphabet!(other) do
    raise ArgumentError,
          "Alphabet must be a literal string or supported atom, got: #{inspect(other)}"
  end

  # Smallest number of digits in `base` that can represent every 128-bit value.
  defp encoded_length(base, length \\ 0, capacity \\ 1) do
    if capacity >= 1 <<< 128,
      do: length,
      else: encoded_length(base, length + 1, capacity * base)
  end

  defp ascii?(string), do: string == for(<<c <- string>>, c < 128, into: "", do: <<c>>)

  # Encoded strings are decoded by matching symbols codepoint by codepoint, which is
  # only unambiguous if no symbol is a prefix of another one.
  defp validate_prefix_free!(graphemes) do
    for a <- graphemes, b <- graphemes, a != b, String.starts_with?(b, a) do
      raise ArgumentError,
            "Alphabet characters must not be a prefix of other characters, " <>
              "got #{inspect(a)} and #{inspect(b)}"
    end

    :ok
  end

  # Encoded IDs may pass through systems that apply Unicode normalization (NFC/NFD).
  # These checks guarantee that a normalized ID either decodes to the original UUID
  # or fails to decode, but never decodes to a different UUID.
  defp validate_normalization_safe!(graphemes) do
    # 1. Each character must be in NFC form, so normalization cannot turn one
    #    character into another one (e.g. KELVIN SIGN into "K").
    for g <- graphemes, String.normalize(g, :nfc) != g do
      raise ArgumentError,
            "Alphabet characters must be in Unicode NFC form, got #{inspect(g)} " <>
              "(NFC: #{inspect(String.normalize(g, :nfc))})"
    end

    # 2. Normalization must not reorder combining marks across character
    #    boundaries, which could swap two digits without changing the length.
    nfd = Map.new(graphemes, &{&1, String.normalize(&1, :nfd)})

    for a <- graphemes, b <- graphemes, String.normalize(a <> b, :nfd) != nfd[a] <> nfd[b] do
      raise ArgumentError,
            "Alphabet characters #{inspect(a)} and #{inspect(b)} are reordered by " <>
              "Unicode normalization when placed next to each other"
    end

    # 3. The decomposed characters must still form a uniquely decodable code, so that
    #    composing or decomposing characters can never produce another valid ID.
    unless uniquely_decodable?(Map.values(nfd)) do
      raise ArgumentError,
            "Alphabet characters can be confused with each other after Unicode " <>
              "normalization (NFC/NFD)"
    end

    :ok
  end

  # Sardinas-Patterson test for unique decodability of a set of words.
  defp uniquely_decodable?(words) do
    word_set = Map.new(words, &{&1, true})

    if map_size(word_set) != length(words) do
      false
    else
      first = for u <- words, v <- words, s = dangling_suffix(u, v), uniq: true, do: s
      sardinas_patterson(first, words, word_set, %{})
    end
  end

  defp sardinas_patterson([], _words, _word_set, _seen), do: true

  defp sardinas_patterson(current, words, word_set, seen) do
    if Enum.any?(current, &Map.has_key?(word_set, &1)) do
      false
    else
      seen = Enum.into(current, seen, &{&1, true})

      next =
        for w <- current,
            u <- words,
            s <- [dangling_suffix(u, w), dangling_suffix(w, u)],
            s != nil and not Map.has_key?(seen, s),
            uniq: true,
            do: s

      sardinas_patterson(next, words, word_set, seen)
    end
  end

  # Returns the rest of `word` if `prefix` is a proper prefix of it, otherwise nil.
  defp dangling_suffix(prefix, word) do
    size = byte_size(prefix)

    case word do
      <<^prefix::binary-size(^size), rest::binary>> when rest != "" -> rest
      _ -> nil
    end
  end
end
