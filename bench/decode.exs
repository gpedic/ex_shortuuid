# Run with: mix run bench/decode.exs
#
# The benchmarked functions live in a module so they are compiled. Anonymous
# functions defined at the top level of a script are interpreted, which adds
# several times the cost of the decode itself.
defmodule Bench.Decode do
  defmodule Base58 do
    use ShortUUID.Builder, alphabet: :base58
  end

  defmodule Base32 do
    use ShortUUID.Builder, alphabet: :base32
  end

  # Not ASCII, so it uses the general codepoint decoder
  defmodule Greek do
    use ShortUUID.Builder, alphabet: "αβγδεζηθικλμνξοπρστυφχψω"
  end

  @uuid "2a162ee5-02f4-4701-9e87-72762cbce5e2"

  def run do
    default = ShortUUID.encode!(@uuid)
    base58 = Base58.encode!(@uuid)
    base32 = Base32.encode!(@uuid)
    greek = Greek.encode!(@uuid)

    Benchee.run(
      %{
        "decode/1 default (base57)" => fn -> ShortUUID.decode(default) end,
        "decode/1 base58" => fn -> Base58.decode(base58) end,
        "decode/1 base32" => fn -> Base32.decode(base32) end,
        "decode/1 greek (non-ASCII)" => fn -> Greek.decode(greek) end,
        "decode/1 invalid input" => fn -> ShortUUID.decode("not a short id") end
      },
      warmup: 1,
      time: 5,
      print: [configuration: false]
    )
  end
end

Bench.Decode.run()
