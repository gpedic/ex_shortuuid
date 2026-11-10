# ShortUUID usage rules

ShortUUID converts existing UUIDs to short strings and back.

- It does not generate UUIDs. Generate them with `Ecto.UUID.generate/0`,
  [Uniq](https://hex.pm/packages/uniq) or similar, then encode them.
- `ShortUUID.encode/1` and `ShortUUID.decode/1` use the default alphabet
  `:base57_shortuuid`, the same default as Python's `shortuuid`.
- For a different alphabet, define a module and call it the same way:

  ```elixir
  defmodule MyApp.ShortID do
    use ShortUUID.Builder, alphabet: :base58
  end

  MyApp.ShortID.encode("550e8400-e29b-41d4-a716-446655440000")
  ```

  The alphabet must be a predefined atom or a literal string; it is validated
  at compile time. Don't call `ShortUUID.Core` directly.
- Never change a module's alphabet once short IDs are stored or shared. The
  same UUID gets a different short ID, and old IDs can silently decode to a
  different, valid UUID instead of failing.
- On untrusted input use `decode/1` and `encode/1`, which return
  `{:error, message}` for any invalid term and never raise. `decode!/1` and
  `encode!/1` raise `ArgumentError`.
- `encode/1` accepts UUIDs with or without hyphens, in curly braces or as
  `urn:uuid:`, in any letter case. `decode/1` always returns a lowercase,
  hyphenated UUID.
- Short IDs are case-sensitive. Don't downcase, trim or otherwise normalize them.
- `:base64` and custom alphabets may contain characters that need escaping in
  URLs; the other predefined alphabets are URL-safe.
- To share IDs with Python `shortuuid` or Node.js `short-uuid`, use an alphabet
  marked compatible in the README's compatibility table. A mismatched alphabet
  decodes to the wrong UUID instead of failing.
- For prefixed IDs like `usr_H9cNmGXLEc8NWcZzSThA9S`, which `ShortUUID.Builder`
  can't produce, write a module that implements `ShortUUID.Behaviour` and wraps
  `ShortUUID` (see the README's "Implementing Compatible Modules"). Its `decode/1`
  must accept exactly what `encode/1` produces: match the fixed prefix and pass
  the rest to `ShortUUID.decode/1`, never return the input unchecked.
- Define `__shortuuid__/0` with `canonical: true` in a hand-written module only
  if every UUID has exactly one accepted ID. Libraries such as ecto_shortuuid
  trust it and skip their own check.
- For Ecto schemas, use the `ecto_shortuuid` package instead of converting by hand.
