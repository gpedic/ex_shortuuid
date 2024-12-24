# ShortUUID

![Build Status](https://github.com/gpedic/ex_shortuuid/actions/workflows/ci.yml/badge.svg?branch=master)
[![Coverage Status](https://coveralls.io/repos/github/gpedic/ex_shortuuid/badge.svg)](https://coveralls.io/github/gpedic/ex_shortuuid)
[![Module Version](https://img.shields.io/hexpm/v/shortuuid.svg)](https://hex.pm/packages/shortuuid)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/shortuuid/)
[![Total Download](https://img.shields.io/hexpm/dt/shortuuid.svg)](https://hex.pm/packages/shortuuid)
[![License](https://img.shields.io/hexpm/l/shortuuid.svg)](https://github.com/gpedic/ex_shortuuid/blob/master/LICENSE.md)
[![Last Updated](https://img.shields.io/github/last-commit/gpedic/shortuuid.svg)](https://github.com/gpedic/ex_shortuuid/commits/master)

<!-- MDOC !-->

ShortUUID is a lightweight Elixir library for generating short, unique IDs in URLs. It turns standard UUIDs into smaller strings ideal for use in URLs.
You can choose from a set of predefined alphabets or define your own. 
The default alphabet includes lowercase letters, uppercase letters, and digits, omitting characters like 'l', '1', 'I', 'O', and '0' to keep them readable.

**Note:** Different ShortUUID implementations be compatible as long as they use the same alphabet. However, there is no official standard, so if you plan to use ShortUUID with other libraries, it's a good idea to research and test for compatibility.

Unlike some other solutions, ShortUUID does not produce UUIDs on its own as there are already plenty of libraries to do so. To generate UUIDs, use libraries such as
[Elixir UUID](https://github.com/zyro/elixir-uuid), [Erlang UUID](https://github.com/okeuday/uuid) and also [Ecto](https://hexdocs.pm/ecto/Ecto.UUID.html) as it can generate version 4 UUIDs.

ShortUUID supports common UUID formats and is case-insensitive.

## Compatibility

### v4.0.0 breaking changes

Raw binary UUID input (as `<<...>>`) is no longer supported. UUIDs must be provided as strings in standard UUID format (`"xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"`) or as 32-character hex strings without hyphens.

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
- Padding characters appear at the end of the string
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
    {:shortuuid, "~> 4.0"}
  ]
end
```

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

It provides a custom Ecto type which allows for ShortUUID primary and foreign keys while staying compatible with `:binary_key` (`EctoUUID`).

## Custom Alphabets

Starting with version `v4.0.0`, ShortUUID allows you to define custom alphabets for encoding and decoding UUIDs. You can use predefined alphabets or define your own.

### Restrictions

- The alphabet must contain at least 16 unique characters.
- The alphabet must not contain duplicate characters.

### Predefined Alphabets

Starting with version `v4.0.0`, the following predefined alphabets are available:

- `:base57` - "23456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz" (default)
- `:base32` - "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
- `:base32_crockford` - "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
- `:base32_hex` - "0123456789ABCDEFGHIJKLMNOPQRSTUV"
- `:base32_rfc4648` - "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
- `:base32_z` - "ybndrfg8ejkmcpqxot1uwisza345h769"
- `:base58` - "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
- `:base62` - "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
- `:base64` - "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
- `:base64_url` - "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"

### Using a custom or predefined alphabet

```elixir
defmodule MyPredefinedUUID do
  use ShortUUID.Builder, alphabet: :base64_url
end

defmodule MyCustomUUID do
  use ShortUUID.Builder, alphabet: "0123456789ABCDEF"
end

iex> MyCustomUUID.encode("550e8400-e29b-41d4-a716-446655440000")
{:ok, "H9cNmGXLEc8NWcZzSThA9S"}

iex> MyCustomUUID.decode("H9cNmGXLEc8NWcZzSThA9S")
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

## Documentation

Look up the full documentation at [https://hexdocs.pm/shortuuid](https://hexdocs.pm/shortuuid).

## Acknowledgments

Inspired by [shortuuid](https://github.com/skorokithakis/shortuuid).

## Copyright and License

Copyright (c) 2024 Goran Pedić

This work is free. You can redistribute it and/or modify it under the
terms of the MIT License. 

See the [LICENSE.md](./LICENSE.md) file for more details.