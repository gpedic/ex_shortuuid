defmodule ShortUUIDTest do
  use ExUnit.Case
  doctest ShortUUID

  @niluuid "00000000-0000-0000-0000-000000000000"

  describe "encoder" do
    test "should pad shorter ints" do
      uuid = "00000001-0001-0001-0001-000000000001"
      assert {:ok, "UD6ibhr3V4YXvriP822222"} = ShortUUID.encode(uuid)
    end

    test "should handle encoding nil UUID" do
      assert {:ok, "2222222222222222222222"} = ShortUUID.encode(@niluuid)
      assert "2222222222222222222222" = ShortUUID.encode!(@niluuid)
    end

    test "should encode regular UUIDs" do
      assert {:ok, "keATfB8JP2ggT7U9JZrpV9"} =
               ShortUUID.encode("2a162ee5-02f4-4701-9e87-72762cbce5e2")

      assert "keATfB8JP2ggT7U9JZrpV9" = ShortUUID.encode!("2a162ee5-02f4-4701-9e87-72762cbce5e2")

      assert {:ok, "keATfB8JP2ggT7U9JZrpV9"} =
               ShortUUID.encode("2a162ee502f447019e8772762cbce5e2")

      assert "keATfB8JP2ggT7U9JZrpV9" = ShortUUID.encode!("2a162ee502f447019e8772762cbce5e2")
    end

    test "should encode UUIDs in curly braces" do
      assert {:ok, "keATfB8JP2ggT7U9JZrpV9"} =
               ShortUUID.encode("{2a162ee5-02f4-4701-9e87-72762cbce5e2}")

      assert {:ok, "keATfB8JP2ggT7U9JZrpV9"} =
               ShortUUID.encode("{2a162ee502f447019e8772762cbce5e2}")
    end

    test "should encode uppercase UUIDs" do
      assert {:ok, "keATfB8JP2ggT7U9JZrpV9"} =
               ShortUUID.encode("2A162EE5-02F4-4701-9E87-72762CBCE5E2")

      assert {:ok, "keATfB8JP2ggT7U9JZrpV9"} =
               ShortUUID.encode("{2A162EE5-02F4-4701-9E87-72762CBCE5E2}")

      assert {:ok, "keATfB8JP2ggT7U9JZrpV9"} =
               ShortUUID.encode("2A162EE502F447019E8772762CBCE5E2")

      assert {:ok, "keATfB8JP2ggT7U9JZrpV9"} =
               ShortUUID.encode("{2A162EE502F447019E8772762CBCE5E2}")
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

    test "encode!/1 raises ArgumentError on invalid input" do
      assert_raise ArgumentError, fn ->
        ShortUUID.encode!("1234")
      end
    end

    test "encode binary UUIDs" do
      assert {:ok, "keATfB8JP2ggT7U9JZrpV9"} =
               ShortUUID.encode(
                 <<0x2A, 0x16, 0x2E, 0xE5, 0x02, 0xF4, 0x47, 0x01, 0x9E, 0x87, 0x72, 0x76, 0x2C,
                   0xBC, 0xE5, 0xE2>>
               )

      assert "keATfB8JP2ggT7U9JZrpV9" =
               ShortUUID.encode!(
                 <<0x2A, 0x16, 0x2E, 0xE5, 0x02, 0xF4, 0x47, 0x01, 0x9E, 0x87, 0x72, 0x76, 0x2C,
                   0xBC, 0xE5, 0xE2>>
               )

      # min
      assert {:ok, "2222222222222222222222"} =
               ShortUUID.encode(<<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>)

      # max
      assert {:ok, "5B8cwPMGnU6qLbRvo7qEZo"} =
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

  describe "decoder" do
    test "decodes empty string to nil uuid" do
      assert {:ok, @niluuid} = ShortUUID.decode("")
      assert @niluuid = ShortUUID.decode!("")
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
      assert {:error, _} = ShortUUID.decode("6B8cwPMGnU6qLbRvo7qEZo")
    end

    test "should still support legacy unpadded strings" do
      assert {:ok, @niluuid} = ShortUUID.decode("")
      assert {:ok, @niluuid} = ShortUUID.decode("222")
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
  end
end
