Benchee.run(%{
  "encode/1 hyphenated uuid string" => fn ->
    ShortUUID.encode("2a162ee5-02f4-4701-9e87-72762cbce5e2")
  end,

  "encode/1 unhyphenated uuid string" => fn ->
    ShortUUID.encode("2a162ee502f447019e8772762cbce5e2")
  end,

  "encode/1 uuid string with braces" => fn ->
    ShortUUID.encode("{2a162ee5-02f4-4701-9e87-72762cbce5e2}")
  end
})
