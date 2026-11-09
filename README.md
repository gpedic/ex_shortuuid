# ShortUUID

[![Build Status](https://github.com/gpedic/ex_shortuuid/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/gpedic/ex_shortuuid/actions/workflows/ci.yml)
[![Coverage Status](https://coveralls.io/repos/github/gpedic/ex_shortuuid/badge.svg)](https://coveralls.io/github/gpedic/ex_shortuuid)
[![Module Version](https://img.shields.io/hexpm/v/shortuuid.svg)](https://hex.pm/packages/shortuuid)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/shortuuid/)
[![Total Download](https://img.shields.io/hexpm/dt/shortuuid.svg)](https://hex.pm/packages/shortuuid)
[![License](https://img.shields.io/hexpm/l/shortuuid.svg)](https://github.com/gpedic/ex_shortuuid/blob/master/LICENSE.md)
[![Last Updated](https://img.shields.io/github/last-commit/gpedic/ex_shortuuid.svg)](https://github.com/gpedic/ex_shortuuid/commits/master)

ShortUUID is a lightweight Elixir library that turns standard UUIDs into shorter strings, for example for use in URLs.
You can choose from a set of predefined alphabets or define your own.
The default alphabet includes lowercase letters, uppercase letters, and digits, omitting characters like 'l', '1', 'I', 'O', and '0' to keep them readable. It is URL-safe.

Not every alphabet is URL-safe: `:base64` and custom alphabets may contain characters that need escaping in URLs (see [Custom Alphabets](#custom-alphabets)).

**Note:** Different ShortUUID implementations are compatible as long as they use the same alphabet in the same order. There is no official standard, so if you plan to use ShortUUID with other libraries, test for compatibility. See [Compatibility with other implementations](#compatibility-with-other-implementations).

Unlike some other solutions, ShortUUID does not produce UUIDs on its own as there are already plenty of libraries to do so. To generate UUIDs, use libraries such as
[Uniq](https://hex.pm/packages/uniq) (including version 7 UUIDs), [Erlang UUID](https://github.com/okeuday/uuid) or [Ecto](https://hexdocs.pm/ecto/Ecto.UUID.html), which can generate version 4 UUIDs.

ShortUUID accepts common UUID formats in any letter case, since UUIDs are case-insensitive:

```elixir
"550e8400-e29b-41d4-a716-446655440000"           # with hyphens
"550e8400e29b41d4a716446655440000"               # without hyphens
"{550e8400-e29b-41d4-a716-446655440000}"         # in curly braces
"urn:uuid:550e8400-e29b-41d4-a716-446655440000"  # as a URN (RFC 9562)
```

Encoded short IDs are case-sensitive: `"abc"` and `"ABC"` are different IDs.

## Compatibility

### Compatibility with other implementations

ShortUUID encodes the most significant bits first and pads with the first alphabet character at the start, like Python's [shortuuid](https://github.com/skorokithakis/shortuuid) and Node.js [short-uuid](https://github.com/oculus42/short-uuid).
Encoded IDs are interchangeable as long as both sides use the same alphabet in the same order.

Python's `shortuuid` sorts custom alphabets, so only alphabets that are already sorted produce the same IDs.
A mismatch is silent: the ID decodes to a different, valid UUID instead of failing.

| Alphabet | Python `shortuuid` | Node.js `short-uuid` |
|---|---|---|
| `:base57_shortuuid` (default) | yes, default alphabet | yes |
| `:base58` | yes | yes |
| `:base62` | yes | yes |
| `:base32_crockford` | yes | yes |
| `:base32_hex` | yes | yes |
| `:base32`, `:base32_z`, `:base64`, `:base64_url` | no, Python sorts them | yes |
| custom alphabet | only if sorted by codepoint | yes, except characters outside the BMP such as emoji |

ShortUUID is also stricter than both: it rejects IDs that are not exactly the encoded length or that are out of the 128-bit range, where the other libraries may return a UUID.

These results are checked by tests against fixtures generated with pinned versions of both libraries, see [`scripts/compat`](https://github.com/gpedic/ex_shortuuid/tree/master/scripts/compat).

### v4.0.0 breaking changes

Raw binary UUID input (as `<<...>>`) is no longer supported. UUIDs must be provided as strings, in one of the formats listed at the top of this page.

Examples of supported formats:
```elixir
# Supported
"550e8400-e29b-41d4-a716-446655440000"  # With hyphens
"550e8400e29b41d4a716446655440000"      # Without hyphens

# No longer supported in v4.0.0
<<85, 14, 132, 0, 226, 155, 65, 212, 167, 22, 68, 102, 85, 68, 0, 0>>
```

### v3.0.0 breaking changes

Changed bit order and padding behavior to align with other language implementations:
- Most significant bits are now encoded first
- Padding characters are added at the start of the string (leading padding)
- Compatible with Python's [shortuuid](https://github.com/skorokithakis/shortuuid) v1.0.0+ and Node.js [short-uuid](https://github.com/oculus42/short-uuid)

Before `v3.0.0`
```elixir

iex> "00000001-0001-0001-0001-000000000001" |> ShortUUID.encode
{:ok, "UD6ibhr3V4YXvriP822222"}

```

After `v3.0.0`
```elixir

iex> "00000001-0001-0001-0001-000000000001" |> ShortUUID.encode
{:ok, "222228PirvXY4V3rhbi6DU"}

```

To migrate ShortUUIDs created using `< v3.0.0` reverse them before passing to `decode`.

```elixir
# UUID "00000001-0001-0001-0001-000000000001" encoded using v2.1.2 to "UD6ibhr3V4YXvriP822222"
# reversing the encoded string before decode with v3.0.0 will produce the correct result
iex> "UD6ibhr3V4YXvriP822222" |> String.reverse() |> ShortUUID.decode!()
"00000001-0001-0001-0001-000000000001"
```

*Warning:* Decoding ShortUUIDs created using a version `< v3.0.0` without reversing the string first will not fail but produce an incorrect result

```elixir
iex> "UD6ibhr3V4YXvriP822222" |> ShortUUID.decode!() === "00000001-0001-0001-0001-000000000001"
false
iex> "UD6ibhr3V4YXvriP822222" |> ShortUUID.decode()
{:ok, "933997ef-eb92-293f-b202-2a879fc84be9"}
```

## Installation

Add `:shortuuid` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:shortuuid, "~> 4.2"}
  ]
end
```

ShortUUID has no runtime dependencies and supports Elixir 1.8 or later.

## Examples

```elixir
iex> "f98e80e7-9923-4173-8408-98f8254912ad" |> ShortUUID.encode
{:ok, "nQtAWSRQ6ByybDtRs7dQwE"}

iex> "f98e80e7-9923-4173-8408-98f8254912ad" |> ShortUUID.encode!
"nQtAWSRQ6ByybDtRs7dQwE"

iex> "nQtAWSRQ6ByybDtRs7dQwE" |> ShortUUID.decode
{:ok, "f98e80e7-9923-4173-8408-98f8254912ad"}

iex> "nQtAWSRQ6ByybDtRs7dQwE" |> ShortUUID.decode!
"f98e80e7-9923-4173-8408-98f8254912ad"
```

## Using ShortUUID with Ecto

If you would like to use ShortUUID with Ecto schemas try [Ecto.ShortUUID](https://github.com/gpedic/ecto_shortuuid).

It provides a custom Ecto type which allows for ShortUUID primary and foreign keys while staying compatible with `:binary_id` (`Ecto.UUID`).

## Custom Alphabets

Starting with version `v4.0.0`, ShortUUID allows you to define custom alphabets for encoding and decoding UUIDs. You can use predefined alphabets or define your own.

### Restrictions

- The alphabet must contain at least 16 unique characters.
- The alphabet must not contain more than 256 characters.
- The alphabet must not contain duplicate characters.
- No character may be a prefix of another one, e.g. `⭐` and `⭐️` (star + variation selector) cannot be used together.
- Characters must be in Unicode NFC form and must not become confusable with each other under Unicode normalization (see below).

### Combining characters and Unicode normalization

Characters are split into the alphabet by grapheme, as you see them, but encoded IDs are matched exactly by codepoint.
This means alphabets may contain characters that merge visually when placed next to each other, such as combining marks, flag letters (regional indicators), emoji modifiers or `\r` and `\n`.
An ID may then look shorter than its length in alphabet characters.

Some systems (browsers, databases, file systems) apply Unicode normalization, which can change the bytes of such IDs, e.g. turning `e` followed by a combining accent into `é`.
A normalized ID will then fail to decode. Alphabets that could make a normalized ID decode to a *different* UUID are rejected at compile time.
If you need IDs to survive arbitrary text processing, stick to ASCII alphabets.

### URL safety

Alphabets are not required to be URL-safe. Any characters are allowed, including emoji, whitespace, control characters and characters that have a special meaning in URLs such as `+`, `/`, `?`, `#` or `%`.
If you put the encoded IDs into URLs, either pick a URL-safe alphabet or percent-encode them.

All predefined alphabets are URL-safe except `:base64`, which uses `+` and `/`. Use `:base64_url` instead if you need a URL-safe base64 alphabet.

### Predefined Alphabets

Starting with version `v4.0.0`, the following predefined alphabets are available:

- `:base57_shortuuid` - "23456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
- `:base32` - "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
- `:base32_crockford` - "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
- `:base32_hex` - "0123456789ABCDEFGHIJKLMNOPQRSTUV"
- `:base32_z` - "ybndrfg8ejkmcpqxot1uwisza345h769"
- `:base58` - "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
- `:base62` - "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
- `:base64` - "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
- `:base64_url` - "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"

### Using a custom or predefined alphabet

```elixir
defmodule MyBase58UUID do
  use ShortUUID.Builder, alphabet: :base58
end

defmodule MyCustomUUID do
  use ShortUUID.Builder, alphabet: "0123456789ABCDEF"
end

iex> MyBase58UUID.encode("550e8400-e29b-41d4-a716-446655440000")
{:ok, "BWBeN28Vb7cMEx7Ym8AUzs"}

iex> MyBase58UUID.decode("BWBeN28Vb7cMEx7Ym8AUzs")
{:ok, "550e8400-e29b-41d4-a716-446655440000"}
```

### Just for fun

Since v4.0.0 alphabets are not limited to alphanumeric characters either

```elixir
defmodule UnicodeUUID do
  use ShortUUID.Builder, alphabet: "🌟💫✨⭐️🌙🌎🌍🌏🌑🌒🌓🌔🌕🌖🌗🌘"
end

iex> UnicodeUUID.encode("550e8400-e29b-41d4-a716-446655440000")
{:ok, "🌎🌎🌟🌗🌑🌙🌟🌟🌗✨🌒🌔🌙💫🌖🌙🌓🌏💫🌍🌙🌙🌍🌍🌎🌎🌙🌙🌟🌟🌟🌟"}


defmodule SmileyUUID do
  use ShortUUID.Builder, alphabet: "😀😊😄😍🥰😘😜🤪😋🤔😌🧐😐😑😶😮😲😱😴🥱😪😢😭😤😎🤓😇😈👻👽🤖🤡💀"
end

iex> SmileyUUID.encode("550e8400-e29b-41d4-a716-446655440000")
{:ok, "😊🤪😢😘💀🥰😲😊🤡🤖🤔😊😘😤👽🤓👻😊👽😲😋😀😭😇😲🤖"}

```

## Implementing Compatible Modules

Starting with version `v4.1.0`, ShortUUID provides a behaviour that you can implement to create compatible modules.
This is useful if you want to create your own ShortUUID-compatible module with custom functionality while maintaining a consistent interface.

```elixir
defmodule MyCustomShortUUID do
  @behaviour ShortUUID.Behaviour

  @spec encode(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def encode(uuid) do
    # Your custom implementation here
    {:ok, "encoded_" <> uuid}
  end

  @spec encode!(String.t()) :: String.t() | no_return()
  def encode!(uuid) do
    case encode(uuid) do
      {:ok, encoded} -> encoded
      {:error, msg} -> raise ArgumentError, message: msg
    end
  end

  @spec decode(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def decode(encoded) do
    # Your custom implementation here
    if String.starts_with?(encoded, "encoded_") do
      {:ok, String.replace_prefix(encoded, "encoded_", "")}
    else
      {:error, "Invalid format"}
    end
  end

  @spec decode!(String.t()) :: String.t() | no_return()
  def decode!(encoded) do
    case decode(encoded) do
      {:ok, decoded} -> decoded
      {:error, msg} -> raise ArgumentError, message: msg
    end
  end
end
```

The `ShortUUID.Behaviour` requires implementing four callbacks:
- `encode/1` - Encode a UUID into a shorter representation
- `encode!/1` - Same as encode/1 but raises on error
- `decode/1` - Decode a shortened UUID back to standard format
- `decode!/1` - Same as decode/1 but raises on error

Using this behaviour ensures that your custom implementation will be compatible with code expecting a ShortUUID-compatible module.

## Documentation

Look up the full documentation at [https://hexdocs.pm/shortuuid](https://hexdocs.pm/shortuuid).

## Acknowledgments

Inspired by [shortuuid](https://github.com/skorokithakis/shortuuid).

## Copyright and License

Copyright (c) 2017-2026 Goran Pedić

This work is free. You can redistribute it and/or modify it under the
terms of the MIT License.

See the [LICENSE.md](./LICENSE.md) file for more details.