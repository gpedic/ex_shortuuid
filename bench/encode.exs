# Run with: mix run bench/encode.exs
#
# The benchmarked functions live in a module so they are compiled. Anonymous
# functions defined at the top level of a script are interpreted, which adds
# several times the cost of the encode itself.
defmodule Bench.Encode do
  def run do
    Benchee.run(
      %{
        "encode/1 hyphenated uuid string" => fn ->
          ShortUUID.encode("2a162ee5-02f4-4701-9e87-72762cbce5e2")
        end,
        "encode/1 unhyphenated uuid string" => fn ->
          ShortUUID.encode("2a162ee502f447019e8772762cbce5e2")
        end,
        "encode/1 uuid string with braces" => fn ->
          ShortUUID.encode("{2a162ee5-02f4-4701-9e87-72762cbce5e2}")
        end
      },
      warmup: 1,
      time: 5,
      print: [configuration: false]
    )
  end
end

Bench.Encode.run()
