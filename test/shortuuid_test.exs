defmodule ShortUUIDTest do
  use ExUnit.Case
  doctest ShortUUID

  test "handles nil uuid" do
    niluuid = "00000000-0000-0000-0000-000000000000"
    encoded_niluuid = ShortUUID.encode(niluuid)
    assert encoded_niluuid == ""
    assert ShortUUID.decode(encoded_niluuid ) == niluuid
  end
end
