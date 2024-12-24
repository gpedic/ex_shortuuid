defmodule ShortUUID.BuilderTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

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
        :base32_rfc4648,
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

  describe "validation" do
    test "rejects invalid alphabets" do
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
                       use ShortUUID.Builder, alphabet: 12345
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
