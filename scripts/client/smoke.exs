# Checks that the library compiles and works on the oldest Elixir version we
# support for clients (`elixir:` in mix.exs). It runs without any dependencies:
#
#     MIX_ENV=prod mix run scripts/client/smoke.exs
#
# The full test suite needs newer Elixir versions (because of its test
# dependencies), so this script only uses features that work back to the floor.
# Expected IDs were produced with the latest Elixir, so this also checks that
# older Unicode versions split custom alphabets the same way.

defmodule ClientSmoke do
  def check(true, _label), do: :ok
  def check(false, label), do: raise("client smoke check failed: #{label}")

  def define(name, alphabet) do
    module = Module.concat(ClientSmoke, Macro.camelize(name))
    body = quote(do: use(ShortUUID.Builder, alphabet: unquote(alphabet)))
    Module.create(module, body, Macro.Env.location(__ENV__))
    module
  end
end

uuid = "f98e80e7-9923-4173-8408-98f8254912ad"
min = "00000000-0000-0000-0000-000000000000"
max = "ffffffff-ffff-ffff-ffff-ffffffffffff"

# Default alphabet and accepted UUID formats
ClientSmoke.check(ShortUUID.encode("550e8400-e29b-41d4-a716-446655440000") == {:ok, "H9cNmGXLEc8NWcZzSThA9S"}, "default encode")
ClientSmoke.check(ShortUUID.decode("H9cNmGXLEc8NWcZzSThA9S") == {:ok, "550e8400-e29b-41d4-a716-446655440000"}, "default decode")

for input <- [
      "550E8400E29B41D4A716446655440000",
      "{550e8400-e29b-41d4-a716-446655440000}",
      "urn:uuid:550e8400-e29b-41d4-a716-446655440000"
    ] do
  ClientSmoke.check(ShortUUID.encode(input) == {:ok, "H9cNmGXLEc8NWcZzSThA9S"}, "input format #{input}")
end

ClientSmoke.check(ShortUUID.decode("H9cNmGXLEc8NWcZzSThA9s") != {:ok, "550e8400-e29b-41d4-a716-446655440000"}, "case-sensitive IDs")
ClientSmoke.check(match?({:error, _}, ShortUUID.decode("invalid")), "invalid ID")

# Predefined alphabets
for atom <- [:base32, :base32_crockford, :base32_hex, :base32_z, :base57_shortuuid, :base58, :base62, :base64, :base64_url] do
  module = ClientSmoke.define(Atom.to_string(atom), atom)

  for u <- [min, max, uuid] do
    ClientSmoke.check(module.decode(module.encode!(u)) == {:ok, u}, "round trip #{atom} #{u}")
  end
end

# Custom alphabets, including characters that merge when concatenated
custom = [
  {"greek", "\u{3B1}\u{3B2}\u{3B3}\u{3B4}\u{3B5}\u{3B6}\u{3B7}\u{3B8}\u{3B9}\u{3BA}\u{3BB}\u{3BC}\u{3BD}\u{3BE}\u{3BF}\u{3C0}\u{3C1}\u{3C3}\u{3C4}\u{3C5}\u{3C6}\u{3C7}\u{3C8}\u{3C9}", "\u{3C3}\u{3C9}\u{3C5}\u{3B2}\u{3B5}\u{3C4}\u{3BF}\u{3B4}\u{3C1}\u{3C3}\u{3C6}\u{3BA}\u{3C9}\u{3C5}\u{3B4}\u{3C6}\u{3C4}\u{3BA}\u{3B6}\u{3BA}\u{3B6}\u{3BA}\u{3BF}\u{3BD}\u{3C0}\u{3C4}\u{3B2}\u{3C7}"},
  {"combining_mark", "\u{301}0123456789abcde", "e87d7\u{301}d68812306273\u{301}787e71438019c"},
  {"regional_indicator", "\u{1F1E6}0\u{1F1E7}1\u{1F1E8}2\u{1F1E9}3\u{1F1EA}4\u{1F1EB}5\u{1F1EC}6\u{1F1ED}7", "74\u{1F1EA}\u{1F1ED}\u{1F1EA}\u{1F1E6}\u{1F1ED}344\u{1F1E7}1\u{1F1E8}031\u{1F1EA}\u{1F1E8}\u{1F1E6}\u{1F1EA}4\u{1F1EA}7\u{1F1EA}\u{1F1E7}2\u{1F1E8}40\u{1F1E7}\u{1F1EB}6"},
  {"crlf", "\u{A}0123456789ABCD\u{D}", "\u{D}87D7\u{A}D68812306273\u{A}787\u{D}71438019C"},
  {"skin_tone", "\u{1F3FD}\u{1F44B}0123456789abcd", "d76c6\u{1F3FD}c577012\u{1F44B}5162\u{1F3FD}676d60327\u{1F44B}08b"},
  {"zwj", "\u{200D}\u{1F469}0123456789abcd", "d76c6\u{200D}c577012\u{1F469}5162\u{200D}676d60327\u{1F469}08b"},
  {"variation_selector", "\u{FE0F}\u{2B50}0123456789abcd", "d76c6\u{FE0F}c577012\u{2B50}5162\u{FE0F}676d60327\u{2B50}08b"},
  {"hangul_jamo", "\u{1161}\u{1100}0123456789abcd", "d76c6\u{1161}c577012\u{1100}5162\u{1161}676d60327\u{1100}08b"}
]

for {name, alphabet, expected} <- custom do
  module = ClientSmoke.define(name, alphabet)
  ClientSmoke.check(module.encode(uuid) == {:ok, expected}, "custom #{name} encode")
  ClientSmoke.check(module.decode(expected) == {:ok, uuid}, "custom #{name} decode")

  for u <- [min, max] do
    ClientSmoke.check(module.decode(module.encode!(u)) == {:ok, u}, "custom #{name} round trip #{u}")
  end
end

# Invalid alphabets are rejected at compile time
for {label, alphabet} <- [
      {"too short", "0123456789"},
      {"duplicates", "00123456789abcdef"},
      {"prefix", "a\u{301}a0123456789bcdef"},
      {"not NFC", "\u{212A}0123456789ABCDEF"}
    ] do
  rejected =
    try do
      ClientSmoke.define("rejected_#{String.replace(label, " ", "_")}", alphabet)
      false
    rescue
      ArgumentError -> true
    end

  ClientSmoke.check(rejected, "rejects alphabet: #{label}")
end

IO.puts("client smoke checks passed on Elixir #{System.version()} / OTP #{System.otp_release()}")
