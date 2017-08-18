defmodule ShortUUIDTest do
  use ExUnit.Case
  doctest ShortUUID

  test "handles nil uuid" do
    niluuid = "00000000-0000-0000-0000-000000000000"
    encoded_niluuid = ShortUUID.encode(niluuid)
    assert encoded_niluuid == ""
    assert ShortUUID.decode(encoded_niluuid ) == niluuid
  end

  test "handles curly braces in uuid" do
    uuid = "{2a162ee5-02f4-4701-9e87-72762cbce5e2}"
    assert ShortUUID.encode(uuid) == "keATfB8JP2ggT7U9JZrpV9"
  end
end
