defmodule ShortUUID.CoreTest do
  use ExUnit.Case, async: true
  use ExUnitProperties
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

  describe "ASCII decode index" do
    @ascii_alphabets [
      "23456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz",
      "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz",
      "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567",
      "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_",
      "0123456789abcdef"
    ]

    test "is used only when every symbol is a single ASCII character" do
      assert {:shortuuid_ascii_index, _} = Core.build_decode_index(["a", "b", "~"])
      assert {:shortuuid_decode_index, _, _} = Core.build_decode_index(["a", "é"])
      assert {:shortuuid_decode_index, _, _} = Core.build_decode_index(["a", "bc"])
    end

    test "rejects duplicate symbols" do
      assert_raise ArgumentError, ~r/must not be empty or a prefix/, fn ->
        Core.build_decode_index(["a", "b", "a"])
      end
    end

    test "rejects wrong lengths, non-ASCII bytes and out-of-range values" do
      for alphabet <- @ascii_alphabets do
        {symbols, base, length, index} = ascii_setup(alphabet)

        {:ok, valid} =
          Core.encode_binary(
            "2a162ee5-02f4-4701-9e87-72762cbce5e2",
            base,
            List.to_tuple(symbols),
            length,
            hd(symbols)
          )

        <<_, tail::binary>> = valid

        assert {:ok, "2a162ee5-02f4-4701-9e87-72762cbce5e2"} =
                 Core.decode_string(valid, base, index, length)

        for bad <- [
              tail,
              valid <> hd(symbols),
              <<0xFF>> <> tail,
              "é" <> binary_part(tail, 1, byte_size(tail) - 1),
              "",
              "\0" <> tail
            ] do
          assert {:error, "Invalid input"} = Core.decode_string(bad, base, index, length)
        end

        max = String.duplicate(List.last(symbols), length)

        assert Core.decode_string(max, base, index, length) ==
                 reference_decode(max, symbols, base, length)
      end
    end

    property "accepts and rejects exactly what a reference decoder does" do
      check all(
              alphabet <- member_of(@ascii_alphabets),
              {symbols, base, length, index} = ascii_setup(alphabet),
              parts <-
                list_of(
                  frequency([
                    {20, member_of(symbols)},
                    {1, binary(length: 1)},
                    {1, string(:utf8, length: 1)}
                  ]),
                  min_length: length - 1,
                  max_length: length + 1
                ),
              max_runs: 2_000
            ) do
        input = Enum.join(parts)

        assert Core.decode_string(input, base, index, length) ==
                 reference_decode(input, symbols, base, length)
      end
    end

    property "round-trips every UUID" do
      check all(
              alphabet <- member_of(@ascii_alphabets),
              {symbols, base, length, index} = ascii_setup(alphabet),
              bytes <- binary(length: 16)
            ) do
        uuid = Core.format_uuid(:binary.decode_unsigned(bytes))

        {:ok, encoded} =
          Core.encode_binary(uuid, base, List.to_tuple(symbols), length, hd(symbols))

        assert Core.decode_string(encoded, base, index, length) == {:ok, uuid}
      end
    end

    defp ascii_setup(alphabet) do
      symbols = String.graphemes(alphabet)
      base = length(symbols)
      length = ceil(128 / :math.log2(base))
      index = Core.build_decode_index(symbols)
      {:shortuuid_ascii_index, _} = index
      {symbols, base, length, index}
    end

    # Straightforward decoder to compare against: valid UTF-8, exactly `length`
    # codepoints, all of them symbols, and a value that fits in 128 bits.
    defp reference_decode(input, symbols, base, length) do
      values = symbols |> Enum.with_index() |> Map.new()

      with true <- String.valid?(input),
           codepoints = String.codepoints(input),
           true <- Kernel.length(codepoints) == length,
           true <- Enum.all?(codepoints, &Map.has_key?(values, &1)),
           value = Enum.reduce(codepoints, 0, &(&2 * base + Map.fetch!(values, &1))),
           true <- value < 2 ** 128 do
        {:ok, Core.format_uuid(value)}
      else
        _ -> {:error, "Invalid input"}
      end
    end
  end
end
