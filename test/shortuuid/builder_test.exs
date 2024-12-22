defmodule ShortUUID.BuilderTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  import ShortUUID.TestGenerators

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
      assert String.starts_with?(encoded, "0")  # "0" is first char in alphabet
      assert {:ok, ^uuid} = CustomAlphabet.decode(encoded)
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

        Module.create(module_name, quote do
          use ShortUUID.Builder, alphabet: unquote(alphabet)
        end, Macro.Env.location(__ENV__))

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
      assert_raise ArgumentError, ~r/at least 16/, fn ->
        defmodule TooShortAlphabet do
          use ShortUUID.Builder, alphabet: "abc"
        end
      end
    end

    test "rejects duplicate characters" do
      assert_raise ArgumentError, ~r/duplicate/, fn ->
        defmodule DuplicateChars do
          use ShortUUID.Builder, alphabet: String.duplicate("a", 32)
        end
      end
    end

    test "validates alphabet is a string" do
      assert_raise ArgumentError, ~r/must be a string/, fn ->
        defmodule InvalidType do
          use ShortUUID.Builder, alphabet: ~c"not a string"
        end
      end
    end
  end

  @tag property: true
  test "custom alphabets maintain encoding length" do
    check all(test_alphabet <- valid_alphabet_generator(),
             uuid <- uuid_generator()) do
      module_name = Module.concat(["ShortUUID", "BuilderTest", "Test#{System.unique_integer()}"])

      Module.create(module_name, quote do
        use ShortUUID.Builder, alphabet: unquote(test_alphabet)
      end, Macro.Env.location(__ENV__))

      {:ok, encoded} = module_name.encode(uuid)
      expected_length = ceil(:math.log(2 ** 128) / :math.log(String.length(test_alphabet)))
      assert String.length(encoded) == expected_length
    end
  end

  @tag property: true
  test "encode/decode works with randomly generated valid alphabets" do
    check all(test_alphabet <- valid_alphabet_generator()) do
      # Use elixir_uuid to generate a standard UUID
      uuid = UUID.uuid4()

      module_name = Module.concat(["ShortUUID", "BuilderTest", "Dyn#{System.unique_integer()}"])

      Module.create(module_name, quote do
        use ShortUUID.Builder, alphabet: unquote(test_alphabet)
      end, Macro.Env.location(__ENV__))

      {:ok, encoded} = module_name.encode(uuid)
      {:ok, decoded} = module_name.decode(encoded)

      assert decoded == uuid
    end
  end
end
