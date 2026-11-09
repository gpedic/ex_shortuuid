defmodule ShortUUID.BuilderTest do
  use ExUnit.Case, async: true
  use ExUnitProperties
  doctest ShortUUID.Builder

  import ShortUUID.TestGenerators
  import StreamData

  describe "custom alphabets" do
    defmodule CustomAlphabet do
      use ShortUUID.Builder, alphabet: "0123456789ABCDEF"
    end

    test "works with custom alphabet" do
      uuid = "00000000-0000-0000-0000-000000000001"
      {:ok, encoded} = CustomAlphabet.encode(uuid)
      {:ok, decoded} = CustomAlphabet.decode(encoded)
      assert decoded == uuid
    end

    test "uses first character for zero padding" do
      uuid = "00000000-0000-0000-0000-000000000000"
      {:ok, encoded} = CustomAlphabet.encode(uuid)
      # "0" is first char in alphabet
      assert String.starts_with?(encoded, "0")
      assert {:ok, ^uuid} = CustomAlphabet.decode(encoded)
    end

    test "supports unicode characters in custom alphabets" do
      defmodule UnicodeUUID do
        use ShortUUID.Builder, alphabet: "🌟💫✨⭐️🌙🌎🌍🌏🌑🌒🌓🌔🌕🌖🌗🌘"
      end

      uuid = UUID.uuid4()
      {:ok, encoded} = UnicodeUUID.encode(uuid)
      {:ok, decoded} = UnicodeUUID.decode(encoded)

      assert decoded == uuid
      assert String.length(encoded) == 32

      defmodule SmileyUUID do
        use ShortUUID.Builder,
          alphabet: "😀😃😄😁😅😂🤣😊😇😉😌😍🥰😘😋😛😜🤪😝🤑🤗🤔🤨😐😑😶😏😒🙄😬🤥😪😴🤤😷🤒🤕🤢🤮🤧🥵🥶🥴😵🤯🤠🥳😎🤓🧐😕😟🙁😓😮😯😲😳🥺😦😧😨😰"
      end

      {:ok, encoded2} = SmileyUUID.encode(uuid)
      {:ok, decoded2} = SmileyUUID.decode(encoded2)

      assert decoded2 == uuid
      assert String.length(encoded2) == 22
    end
  end

  describe "predefined alphabets" do
    test "all predefined alphabets handle encode/decode cycle" do
      test_uuid = "550e8400-e29b-41d4-a716-446655440000"
      nil_uuid = "00000000-0000-0000-0000-000000000000"

      predefined_alphabets = [
        :base57_shortuuid,
        :base32,
        :base32_crockford,
        :base32_hex,
        :base32_z,
        :base58,
        :base62,
        :base64,
        :base64_url
      ]

      for alphabet <- predefined_alphabets do
        module_name = Module.concat(["ShortUUID", "BuilderTest", "#{alphabet}"])

        Module.create(
          module_name,
          quote do
            use ShortUUID.Builder, alphabet: unquote(alphabet)
          end,
          Macro.Env.location(__ENV__)
        )

        # Test regular UUID encoding/decoding
        {:ok, encoded} = module_name.encode(test_uuid)
        assert is_binary(encoded)
        assert {:ok, ^test_uuid} = module_name.decode(encoded)

        # Test nil UUID (all zeros) encoding/decoding
        {:ok, encoded_nil} = module_name.encode(nil_uuid)
        assert {:ok, ^nil_uuid} = module_name.decode(encoded_nil)
      end
    end
  end

  describe "alphabets with characters that merge when concatenated" do
    # Adjacent symbols in these alphabets render as a single grapheme
    # (combining marks, regional indicators, CR LF, emoji modifiers, ZWJ,
    # variation selectors, Hangul jamo). Encoding and decoding must still work.
    @merging_alphabets %{
      CombiningMark: "\u0301" <> "0123456789abcde",
      RegionalIndicator: "🇦0🇧1🇨2🇩3🇪4🇫5🇬6🇭7",
      CrLf: "\n0123456789ABCD\r",
      SkinTone: "🏽👋" <> "0123456789abcd",
      Zwj: "\u200D👩" <> "0123456789abcd",
      VariationSelector: "\uFE0F⭐" <> "0123456789abcd",
      HangulJamo: "\u1161\u1100" <> "0123456789abcd"
    }

    for {name, alphabet} <- @merging_alphabets do
      Module.create(
        Module.concat(__MODULE__, name),
        quote(do: use(ShortUUID.Builder, alphabet: unquote(alphabet))),
        Macro.Env.location(__ENV__)
      )
    end

    @merging_modules Enum.map(Map.keys(@merging_alphabets), &Module.concat(__MODULE__, &1))

    test "encode and decode the boundary UUIDs" do
      for module <- @merging_modules,
          uuid <- [
            "00000000-0000-0000-0000-000000000000",
            "00000000-0000-0000-0000-000000000001",
            "ffffffff-ffff-ffff-ffff-ffffffffffff"
          ] do
        assert {:ok, encoded} = module.encode(uuid), "#{inspect(module)} failed on #{uuid}"
        assert {:ok, ^uuid} = module.decode(encoded), "#{inspect(module)} failed on #{uuid}"
      end
    end

    @tag property: true
    test "round-trip every UUID" do
      check all(uuid <- uuid_generator(), max_runs: 300) do
        expected = uuid |> String.trim_leading("{") |> String.trim_trailing("}") |> normalize()

        for module <- @merging_modules do
          assert {:ok, encoded} = module.encode(uuid)
          assert {:ok, ^expected} = module.decode(encoded)
        end
      end
    end

    @tag property: true
    test "Unicode normalization never decodes to a different UUID" do
      check all(uuid <- uuid_generator(), form <- member_of([:nfc, :nfd]), max_runs: 300) do
        for module <- @merging_modules do
          {:ok, encoded} = module.encode(uuid)
          {:ok, expected} = module.decode(encoded)

          case module.decode(String.normalize(encoded, form)) do
            {:ok, decoded} -> assert decoded == expected
            {:error, _} -> :ok
          end
        end
      end
    end

    test "symbols are counted by codepoint, not by grapheme" do
      module = Module.concat(__MODULE__, CombiningMark)
      mark = "\u0301"
      {:ok, encoded} = module.encode("00000000-0000-0000-0000-000000000000")

      # 32 combining marks render as a single grapheme but are 32 symbols
      assert encoded == String.duplicate(mark, 32)
      assert String.length(encoded) == 1

      # one symbol too few or too many is rejected
      assert {:error, _} = module.decode(String.duplicate(mark, 31))
      assert {:error, _} = module.decode(String.duplicate(mark, 33))
    end

    defp normalize(uuid) do
      hex = uuid |> String.replace("-", "") |> String.downcase()
      <<a::binary-8, b::binary-4, c::binary-4, d::binary-4, e::binary-12>> = hex
      Enum.join([a, b, c, d, e], "-")
    end
  end

  describe "validation" do
    test "rejects alphabets where a character is a prefix of another" do
      assert_raise ArgumentError, ~r/must not be a prefix of other characters/, fn ->
        defmodule PrefixAlphabet do
          use ShortUUID.Builder, alphabet: "⭐⭐\uFE0F0123456789abcd"
        end
      end
    end

    test "rejects characters that are not in NFC form" do
      # KELVIN SIGN normalizes to "K"
      assert_raise ArgumentError, ~r/must be in Unicode NFC form/, fn ->
        defmodule KelvinAlphabet do
          use ShortUUID.Builder, alphabet: "\u212A0123456789abcde"
        end
      end

      # decomposed "é"
      assert_raise ArgumentError, ~r/must be in Unicode NFC form/, fn ->
        defmodule DecomposedAlphabet do
          use ShortUUID.Builder, alphabet: "e\u03010123456789ABCDE"
        end
      end
    end

    test "rejects characters reordered by normalization" do
      # "x" + acute (combining class 230) followed by dot below (220) is
      # reordered by NFC/NFD, which would swap two digits.
      assert_raise ArgumentError, ~r/are reordered by Unicode normalization/, fn ->
        defmodule ReorderAlphabet do
          use ShortUUID.Builder, alphabet: "\u0323x\u03010123456789abcd"
        end
      end
    end

    test "rejects characters confusable after normalization" do
      # "e" followed by a combining acute is canonically equivalent to "é"
      assert_raise ArgumentError, ~r/can be confused with each other/, fn ->
        defmodule ConfusableAlphabet do
          use ShortUUID.Builder, alphabet: "\u0301eé0123456789abc"
        end
      end
    end

    test "accepts accented letters next to their base letters" do
      defmodule AccentAlphabet do
        use ShortUUID.Builder, alphabet: "eéèêaàâoô0123456"
      end

      uuid = "550e8400-e29b-41d4-a716-446655440000"
      assert {:ok, encoded} = AccentAlphabet.encode(uuid)
      assert {:ok, ^uuid} = AccentAlphabet.decode(encoded)
    end

    test "rejects invalid alphabets" do
      assert_raise ArgumentError, "Unknown alphabet atom: :not_an_alphabet", fn ->
        defmodule UnknownAlphabet do
          use ShortUUID.Builder, alphabet: :not_an_alphabet
        end
      end

      assert_raise ArgumentError, "Alphabet must contain at least 16 characters", fn ->
        defmodule TooShortAlphabet do
          use ShortUUID.Builder, alphabet: "abc"
        end
      end

      assert_raise ArgumentError, "Alphabet must not contain duplicate characters", fn ->
        defmodule DuplicateChars do
          use ShortUUID.Builder, alphabet: "AABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
        end
      end

      assert_raise ArgumentError,
                   "Alphabet must be a literal string or supported atom, got: 12345",
                   fn ->
                     defmodule InvalidType do
                       use ShortUUID.Builder, alphabet: 12_345
                     end
                   end

      assert_raise ArgumentError,
                   "Alphabet must be a literal string or supported atom, got: [\"a\", \"b\", \"c\"]",
                   fn ->
                     defmodule InvalidFunctionCall do
                       use ShortUUID.Builder, alphabet: ["a", "b", "c"]
                     end
                   end
    end

    test "rejects too long alphabets" do
      assert_raise ArgumentError, "Alphabet must not contain more than 256 characters", fn ->
        defmodule TooLongAlphabet do
          use ShortUUID.Builder, alphabet: unquote(String.duplicate("*", 257))
        end
      end
    end
  end

  @tag property: true
  test "custom alphabets maintain encoding length" do
    alphabet_generator =
      one_of([
        valid_emoji_alphabet_generator(),
        valid_alphanumeric_alphabet_generator(),
        valid_url_safe_alphabet_generator()
      ])

    check all(
            test_alphabet <- alphabet_generator,
            uuid <- uuid_generator()
          ) do
      module_name = Module.concat(["ShortUUID", "BuilderTest", "Test#{System.unique_integer()}"])

      Module.create(
        module_name,
        quote do
          use ShortUUID.Builder, alphabet: unquote(test_alphabet)
        end,
        Macro.Env.location(__ENV__)
      )

      {:ok, encoded} = module_name.encode(uuid)
      expected_length = ceil(:math.log(2 ** 128) / :math.log(String.length(test_alphabet)))
      assert String.length(encoded) == expected_length
    end
  end

  @tag property: true
  test "encode/decode works with randomly generated valid alphabets" do
    alphabet_generator =
      one_of([
        valid_emoji_alphabet_generator(),
        valid_alphanumeric_alphabet_generator(),
        valid_url_safe_alphabet_generator()
      ])

    check all(test_alphabet <- alphabet_generator) do
      uuid = UUID.uuid4()

      module_name = Module.concat(["ShortUUID", "BuilderTest", "Dyn#{System.unique_integer()}"])

      Module.create(
        module_name,
        quote do
          use ShortUUID.Builder, alphabet: unquote(test_alphabet)
        end,
        Macro.Env.location(__ENV__)
      )

      {:ok, encoded} = module_name.encode(uuid)
      {:ok, decoded} = module_name.decode(encoded)

      assert decoded == uuid
    end
  end
end
