defmodule ShortUUID.CoreTest do
  use ExUnit.Case, async: true
  doctest ShortUUID.Core

  alias ShortUUID.Core

  @test_alphabet "0123456789ABCDEF"
  @test_tuple @test_alphabet |> String.graphemes() |> List.to_tuple()
  @test_index @test_alphabet |> String.graphemes() |> Enum.with_index() |> Map.new()
  @test_base String.length(@test_alphabet)
  @test_length ceil(:math.log(2 ** 128) / :math.log(@test_base))
  # Use first char for zero-padding
  @test_zero_char String.first(@test_alphabet)

  describe "parse_uuid/1" do
    test "handles various UUID formats" do
      uuid = "550e8400-e29b-41d4-a716-446655440000"
      assert {:ok, _} = Core.parse_uuid(uuid)
      assert {:ok, _} = Core.parse_uuid(String.replace(uuid, "-", ""))
      assert {:ok, _} = Core.parse_uuid("{#{uuid}}")
      assert {:ok, _} = Core.parse_uuid("{#{String.replace(uuid, "-", "")}}")
    end

    test "rejects invalid UUIDs" do
      assert {:error, _} = Core.parse_uuid("invalid")
      assert {:error, _} = Core.parse_uuid("")
      assert {:error, _} = Core.parse_uuid(nil)
    end
  end

  describe "encode_binary/5" do
    test "encodes UUIDs with dashes" do
      uuid = "550e8400-e29b-41d4-a716-446655440000"

      assert {:ok, encoded} =
               Core.encode_binary(uuid, @test_base, @test_tuple, @test_length, @test_zero_char)

      assert is_binary(encoded)
      assert String.length(encoded) == @test_length
    end

    test "encodes UUIDs without dashes" do
      uuid = "550e8400e29b41d4a716446655440000"

      assert {:ok, encoded} =
               Core.encode_binary(uuid, @test_base, @test_tuple, @test_length, @test_zero_char)

      assert is_binary(encoded)
      assert String.length(encoded) == @test_length
    end

    test "encodes UUIDs with curly braces" do
      uuid = "{550e8400-e29b-41d4-a716-446655440000}"

      assert {:ok, encoded} =
               Core.encode_binary(uuid, @test_base, @test_tuple, @test_length, @test_zero_char)

      assert is_binary(encoded)
      assert String.length(encoded) == @test_length
    end

    test "handles zero padding correctly" do
      uuid = "00000000-0000-0000-0000-000000000000"

      {:ok, encoded} =
        Core.encode_binary(uuid, @test_base, @test_tuple, @test_length, @test_zero_char)

      assert String.starts_with?(encoded, @test_zero_char)
    end

    test "rejects invalid input" do
      assert {:error, _} =
               Core.encode_binary(
                 "invalid",
                 @test_base,
                 @test_tuple,
                 @test_length,
                 @test_zero_char
               )

      assert {:error, _} =
               Core.encode_binary("", @test_base, @test_tuple, @test_length, @test_zero_char)

      assert {:error, _} =
               Core.encode_binary(nil, @test_base, @test_tuple, @test_length, @test_zero_char)
    end

    test "rejects binary input" do
      binary =
        <<0x55, 0x0E, 0x84, 0x00, 0xE2, 0x9B, 0x41, 0xD4, 0xA7, 0x16, 0x44, 0x66, 0x55, 0x44,
          0x00, 0x00>>

      assert {:error, "Invalid UUID"} =
               Core.encode_binary(binary, @test_base, @test_tuple, @test_length, @test_zero_char)
    end
  end

  describe "decode_string/4" do
    test "decodes valid strings" do
      uuid = "550e8400-e29b-41d4-a716-446655440000"

      {:ok, encoded} =
        Core.encode_binary(uuid, @test_base, @test_tuple, @test_length, @test_zero_char)

      assert {:ok, decoded} = Core.decode_string(encoded, @test_base, @test_index, @test_length)
      assert decoded == uuid
    end

    test "handles zero value correctly" do
      uuid = "00000000-0000-0000-0000-000000000000"

      {:ok, encoded} =
        Core.encode_binary(uuid, @test_base, @test_tuple, @test_length, @test_zero_char)

      assert String.starts_with?(encoded, @test_zero_char)
      assert {:ok, decoded} = Core.decode_string(encoded, @test_base, @test_index, @test_length)
      assert decoded == uuid
    end

    test "rejects invalid length" do
      assert {:error, _} = Core.decode_string("too-short", @test_base, @test_index, @test_length)
    end

    test "rejects invalid characters" do
      valid_length = String.duplicate("X", @test_length)
      assert {:error, _} = Core.decode_string(valid_length, @test_base, @test_index, @test_length)
    end
  end

  describe "round trip encoding/decoding" do
    test "preserves UUID through encode/decode cycle" do
      uuid = "550e8400-e29b-41d4-a716-446655440000"

      {:ok, encoded} =
        Core.encode_binary(uuid, @test_base, @test_tuple, @test_length, @test_zero_char)

      assert {:ok, ^uuid} = Core.decode_string(encoded, @test_base, @test_index, @test_length)
    end

    test "handles edge cases" do
      # nil UUID
      uuid = "00000000-0000-0000-0000-000000000000"

      {:ok, encoded} =
        Core.encode_binary(uuid, @test_base, @test_tuple, @test_length, @test_zero_char)

      assert String.starts_with?(encoded, @test_zero_char)
      assert {:ok, ^uuid} = Core.decode_string(encoded, @test_base, @test_index, @test_length)

      # max UUID
      uuid = "ffffffff-ffff-ffff-ffff-ffffffffffff"

      {:ok, encoded} =
        Core.encode_binary(uuid, @test_base, @test_tuple, @test_length, @test_zero_char)

      assert {:ok, ^uuid} = Core.decode_string(encoded, @test_base, @test_index, @test_length)
    end
  end

  describe "urn:uuid: input" do
    test "accepts the urn:uuid: prefix in any case" do
      assert Core.parse_uuid("urn:uuid:550e8400-e29b-41d4-a716-446655440000") ==
               {:ok, "550e8400e29b41d4a716446655440000"}

      assert Core.parse_uuid("URN:UUID:550E8400-E29B-41D4-A716-446655440000") ==
               {:ok, "550E8400E29B41D4A716446655440000"}
    end

    test "rejects other prefixes and non-hyphenated urns" do
      assert {:error, _} = Core.parse_uuid("urn:uid:550e8400-e29b-41d4-a716-4466554400000")
      assert {:error, _} = Core.parse_uuid("urx:uuid:550e8400-e29b-41d4-a716-446655440000")
      assert {:error, _} = Core.parse_uuid("urn:uuid:550e8400e29b41d4a716446655440000")
      assert {:error, _} = Core.parse_uuid("urn:uuid:{550e8400-e29b-41d4-a716-446655440000}")
    end

    test "is encoded like the plain UUID" do
      assert ShortUUID.encode("urn:uuid:550e8400-e29b-41d4-a716-446655440000") ==
               ShortUUID.encode("550e8400-e29b-41d4-a716-446655440000")
    end
  end

  describe "build_decode_index/1" do
    test "rejects empty, duplicate and prefix symbols" do
      for symbols <- [["", "a"], ["a", "a"], ["ab", "a"], ["a", "ab"]] do
        assert_raise ArgumentError, ~r/must not be empty or a prefix/, fn ->
          Core.build_decode_index(symbols)
        end
      end
    end

    test "decoding rejects invalid UTF-8 and input ending inside a symbol" do
      symbols = ["x\u0301" | String.graphemes("0123456789abcde")]
      index = Core.build_decode_index(symbols)

      {:ok, encoded} =
        Core.encode_binary(
          "ffffffff-ffff-ffff-ffff-ffffffffffff",
          16,
          List.to_tuple(symbols),
          32,
          hd(symbols)
        )

      assert {:ok, _} = Core.decode_string(encoded, 16, index, 32)

      assert {:error, "Invalid input"} = Core.decode_string(<<0xFF>> <> encoded, 16, index, 32)

      assert {:error, "Invalid input"} =
               Core.decode_string(String.duplicate("0", 31) <> "x", 16, index, 32)
    end
  end

  describe "input guards" do
    test "format_uuid/1 rejects values outside the 128-bit range" do
      assert Core.format_uuid(0) == "00000000-0000-0000-0000-000000000000"
      assert Core.format_uuid(2 ** 128 - 1) == "ffffffff-ffff-ffff-ffff-ffffffffffff"
      assert_raise FunctionClauseError, fn -> Core.format_uuid(-1) end
      assert_raise FunctionClauseError, fn -> Core.format_uuid(2 ** 128) end
    end

    test "encode_int/5 returns an error for non-128-bit input" do
      assert {:error, "Invalid UUID"} =
               Core.encode_int("abc", @test_base, @test_tuple, @test_length, @test_zero_char)

      assert {:error, "Invalid UUID"} =
               Core.encode_int(<<1::64>>, @test_base, @test_tuple, @test_length, @test_zero_char)
    end
  end
end
