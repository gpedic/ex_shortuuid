defmodule ShortUUIDTest do
  use ExUnit.Case, async: true
  use ExUnitProperties
  doctest ShortUUID

  @niluuid "00000000-0000-0000-0000-000000000000"

  describe "encode/1" do
    test "should pad shorter ints" do
      uuid = "00000001-0001-0001-0001-000000000001"
      assert {:ok, "222228PirvXY4V3rhbi6DU"} = ShortUUID.encode(uuid)
    end

    test "should handle encoding nil UUID" do
      assert {:ok, "2222222222222222222222"} = ShortUUID.encode(@niluuid)
      assert "2222222222222222222222" = ShortUUID.encode!(@niluuid)
    end

    test "should encode regular UUIDs" do
      assert {:ok, "9VprZJ9U7Tgg2PJ8BfTAek"} =
               ShortUUID.encode("2a162ee5-02f4-4701-9e87-72762cbce5e2")

      assert "9VprZJ9U7Tgg2PJ8BfTAek" = ShortUUID.encode!("2a162ee5-02f4-4701-9e87-72762cbce5e2")

      assert {:ok, "9VprZJ9U7Tgg2PJ8BfTAek"} =
               ShortUUID.encode("2a162ee502f447019e8772762cbce5e2")

      assert "9VprZJ9U7Tgg2PJ8BfTAek" = ShortUUID.encode!("2a162ee502f447019e8772762cbce5e2")
    end

    test "should encode UUIDs in curly braces (MS format)" do
      assert {:ok, "9VprZJ9U7Tgg2PJ8BfTAek"} =
               ShortUUID.encode("{2a162ee5-02f4-4701-9e87-72762cbce5e2}")

      assert {:ok, "9VprZJ9U7Tgg2PJ8BfTAek"} =
               ShortUUID.encode("{2A162EE5-02F4-4701-9E87-72762CBCE5E2}")

      assert {:ok, "9VprZJ9U7Tgg2PJ8BfTAek"} =
               ShortUUID.encode("{2a162ee502f447019e8772762cbce5e2}")

      assert {:ok, "9VprZJ9U7Tgg2PJ8BfTAek"} =
               ShortUUID.encode("{2A162EE502F447019E8772762CBCE5E2}")
    end

    test "should encode uppercase UUIDs" do
      assert {:ok, "9VprZJ9U7Tgg2PJ8BfTAek"} =
               ShortUUID.encode("2A162EE5-02F4-4701-9E87-72762CBCE5E2")

      assert {:ok, "9VprZJ9U7Tgg2PJ8BfTAek"} =
               ShortUUID.encode("2A162EE502F447019E8772762CBCE5E2")

      assert {:ok, "9VprZJ9U7Tgg2PJ8BfTAek"} =
               ShortUUID.encode("2a162EE5-02f4-4701-9e87-72762CBCE5e2")
    end

    test "should not allow invalid UUIDs" do
      assert {:error, _} = ShortUUID.encode("")
      assert {:error, _} = ShortUUID.encode(0)
      assert {:error, _} = ShortUUID.encode(1)
      assert {:error, _} = ShortUUID.encode(nil)
      assert {:error, _} = ShortUUID.encode(true)
      assert {:error, _} = ShortUUID.decode(false)
      # has non hex value
      assert {:error, _} = ShortUUID.encode("FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFG")
      # too short
      assert {:error, _} = ShortUUID.encode("FFFFFFFF-FFFF-FFFF-FFFF-58027")
      # too long
      assert {:error, _} = ShortUUID.encode("FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFFF")
    end

    test "unicode in string errors" do
      assert {:error, "Invalid UUID"} = ShortUUID.encode("2á162ee502f447019e8772762cbce5e2")
      assert {:error, "Invalid UUID"} = ShortUUID.encode("2Ä162ee502f447019e8772762cbce5e2")
    end

    test "encode binary UUIDs" do
      assert {:ok, "nZJHSqgNVBBSX2h6sRUQuP"} =
               ShortUUID.encode(
                 <<250, 98, 175, 128, 168, 97, 69, 108, 171, 119, 213, 103, 126, 46, 139, 168>>
               )

      assert {:ok, "9VprZJ9U7Tgg2PJ8BfTAek"} =
               ShortUUID.encode(
                 <<0x2A, 0x16, 0x2E, 0xE5, 0x02, 0xF4, 0x47, 0x01, 0x9E, 0x87, 0x72, 0x76, 0x2C,
                   0xBC, 0xE5, 0xE2>>
               )

      assert "9VprZJ9U7Tgg2PJ8BfTAek" =
               ShortUUID.encode!(
                 <<0x2A, 0x16, 0x2E, 0xE5, 0x02, 0xF4, 0x47, 0x01, 0x9E, 0x87, 0x72, 0x76, 0x2C,
                   0xBC, 0xE5, 0xE2>>
               )

      # min
      assert {:ok, "2222222222222222222222"} =
               ShortUUID.encode(<<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>)

      # max
      assert {:ok, "oZEq7ovRbLq6UnGMPwc8B5"} =
               ShortUUID.encode(
                 <<255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
                   255>>
               )

      # more than 128 bit
      assert {:error, _} = ShortUUID.encode(<<1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>)

      # less than 128 bit
      assert {:error, _} = ShortUUID.encode(<<1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>)
    end
  end

  describe "encode!/1" do
    test "raises an ArgumentError for and invalid UUID" do
      assert_raise ArgumentError, fn ->
        ShortUUID.encode!("invalid-uuid")
      end
    end
  end

  describe "decode/2" do
    test "decodes a valid shortuuid" do
      assert {:ok, "2a162ee5-02f4-4701-9e87-72762cbce5e2"} =
               ShortUUID.decode("9VprZJ9U7Tgg2PJ8BfTAek")

      assert "2a162ee5-02f4-4701-9e87-72762cbce5e2" = ShortUUID.decode!("9VprZJ9U7Tgg2PJ8BfTAek")
    end

    test "returns an error for an invalid ShortUUID" do
      assert {:error, "Invalid input"} = ShortUUID.decode("invalid-shortuuid")
      assert {:error, "Invalid input"} = ShortUUID.decode("1eATfB8JP2ggT7U9JZrpV9")
    end

    test "fails to decode empty string to nil uuid" do
      assert {:error, "Invalid input"} = ShortUUID.decode("")

      assert_raise ArgumentError, fn ->
        ShortUUID.decode!("")
      end
    end

    test "handles decoding nil UUID" do
      assert {:ok, @niluuid} = ShortUUID.decode("2222222222222222222222")
    end

    test "raises ArgumentError on invalid string" do
      # invalid because contains letter not in alphabet
      assert_raise ArgumentError, fn ->
        ShortUUID.decode!("01lnotinalphabet")
      end

      # invalid because results in too large number
      assert_raise ArgumentError, fn ->
        ShortUUID.decode!("22222222222222222222223")
      end
    end

    test "fails when encoded value is > 128 bit" do
      assert {:error, _} = ShortUUID.decode("oZEq7ovRbLq6UnGMPwc8B6")
    end

    test "should not support legacy unpadded strings" do
      assert {:error, "Invalid input"} = ShortUUID.decode("")
      assert {:error, "Invalid input"} = ShortUUID.decode("222")
    end

    test "unicode in string errors" do
      assert {:error, _} = ShortUUID.decode("2á8cwPMGnU6qLbRvo7qEZo2")
      assert {:error, _} = ShortUUID.decode("2Ä8cwPMGnU6qLbRvo7qEZo2")
    end

    test "these should all error" do
      assert {:error, _} = ShortUUID.decode(nil)
      assert {:error, _} = ShortUUID.decode(0)
      assert {:error, _} = ShortUUID.decode(1)
      assert {:error, _} = ShortUUID.decode(true)
      assert {:error, _} = ShortUUID.decode(false)
    end

    test "decodes legacy shortuuid" do
      assert {:ok, "2a162ee5-02f4-4701-9e87-72762cbce5e2"} =
               ShortUUID.decode("keATfB8JP2ggT7U9JZrpV9", legacy: true)
    end
  end

  describe "decode!/2" do
    test "decodes legacy shortuuid" do
      assert "2a162ee5-02f4-4701-9e87-72762cbce5e2" =
               ShortUUID.decode!("keATfB8JP2ggT7U9JZrpV9", legacy: true)
    end

    test "raises an ArgumentError for and invalid ShortUUID" do
      assert_raise ArgumentError, fn ->
        ShortUUID.decode!("invalid-shortuuid")
      end
    end
  end

  test "random UUID and shortUUID round-trip" do
    uuid = UUID.uuid4()
    {:ok, shortuuid} = ShortUUID.encode(uuid)
    {:ok, uuid2} = ShortUUID.decode(shortuuid)
    assert uuid == uuid2
  end

  # Test the encoding and decoding functionality of ShortUUID.
  property "uuid encoding and decoding (there and back again)" do
    check all(uuid <- uuid_generator()) do
      assert {:ok, encoded_uuid} = ShortUUID.encode(uuid)
      assert {:ok, decoded_uuid} = ShortUUID.decode(encoded_uuid)

      assert normalize(uuid) == decoded_uuid
    end
  end

  property "binary UUID encoding" do
    check all(binary <- random_binary_uuid()) do
      {:ok, _} = ShortUUID.encode(binary)
    end
  end

  # Generates a V4 UUID with a 50% chance of removing hyphens,
  # randomly applies downcasing, upcasing, or capitalization.
  def uuid_generator do
    StreamData.map(StreamData.constant(:ok), fn _ ->
      uuid = UUID.uuid4()

      uuid =
        case :rand.uniform(3) do
          1 -> uuid
          2 -> String.replace(uuid, "-", "")
          3 -> "{#{uuid}}"
        end

      case :rand.uniform(3) do
        1 -> String.downcase(uuid)
        2 -> String.upcase(uuid)
        3 -> String.capitalize(uuid)
      end
    end)
  end

  defp normalize(uuid) do
    uuid
    # Remove non-hex characters
    |> String.replace(~r/[^a-f0-9]/i, "")
    # Convert to lowercase
    |> String.downcase()
    # Add hyphens
    |> String.replace(~r/(.{8})(.{4})(.{4})(.{4})(.{12})/, "\\1-\\2-\\3-\\4-\\5")
  end

  def random_binary_uuid do
    StreamData.binary(length: 16)
  end
end
