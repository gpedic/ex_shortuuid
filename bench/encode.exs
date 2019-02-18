Benchee.run(%{
  "encode/1 binary uuid" => fn ->
    ShortUUID.encode(<<1, 96, 40, 15, 29, 112, 21, 104, 176, 151, 123, 220, 162, 128, 29, 227>>)
  end,

  "encode/1 uuid string" => fn ->
    ShortUUID.encode("2a162ee5-02f4-4701-9e87-72762cbce5e2")
  end,

  "encode/1 uuid string not hyphenated" => fn ->
    ShortUUID.encode("2a162ee502f447019e8772762cbce5e2")
  end,

  "encode/1 uuid string with braces" => fn ->
    ShortUUID.encode("{2a162ee5-02f4-4701-9e87-72762cbce5e2}")
  end
})