# ShortUUID

![Build Status](https://github.com/gpedic/ex_shortuuid/actions/workflows/ci.yml/badge.svg?branch=master)
[![Coverage Status](https://coveralls.io/repos/github/gpedic/ex_shortuuid/badge.svg)](https://coveralls.io/github/gpedic/ex_shortuuid)
[![Module Version](https://img.shields.io/hexpm/v/shortuuid.svg)](https://hex.pm/packages/shortuuid)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/shortuuid/)
[![Total Download](https://img.shields.io/hexpm/dt/shortuuid.svg)](https://hex.pm/packages/shortuuid)
[![License](https://img.shields.io/hexpm/l/shortuuid.svg)](https://github.com/gpedic/ex_shortuuid/blob/master/LICENSE.md)
[![Last Updated](https://img.shields.io/github/last-commit/gpedic/shortuuid.svg)](https://github.com/gpedic/ex_shortuuid/commits/master)

<!-- MDOC !-->

ShortUUID is a lightweight Elixir library that generates short and unique IDs for use in URLs. It provides a solution when you need IDs that are easy to use and understand for users.

Instead of using long and complex UUIDs, ShortUUID converts them into shorter strings using a combination of lowercase and uppercase letters, as well as digits. It avoids using similar-looking characters such as 'l', '1', 'I', 'O', and '0'.

**Note:** It's worth noting that different ShortUUID implementations should work together if they use the same set of characters. However, there is no official standard, so if you plan to use ShortUUID with other libraries, it's a good idea to research and test for compatibility.

Unlike some other libraries, ShortUUID doesn't generate UUIDs itself. Instead, you can input any valid UUID into the `ShortUUID.encode/1`. To generate UUIDs, you can use libraries like
[Elixir UUID](https://github.com/zyro/elixir-uuid), [Erlang UUID](https://github.com/okeuday/uuid) and also [Ecto](https://hexdocs.pm/ecto/Ecto.UUID.html) as it can generate version 4 UUIDs.

ShortUUID supports common UUID formats and is case-insensitive. It also supports binary UUIDs returned from DBs like PostgreSQL when the uuid type is used to store the UUID.

## Compatibility

Starting with version `v3.0.0`, this library will follow suit with changes in other language implementations and move the most significant bit of the encoded value to the start. This also means that padding will be applied to the end of the string, not the start
This change will restore compatibility with other libraries like [shortuuid](https://github.com/skorokithakis/shortuuid) from v1.0.0 onwards and [short-uuid
](https://github.com/oculus42/short-uuid).

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
    {:shortuuid, "~> 2.0"}
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

## Documentation

Look up the full documentation at [https://hexdocs.pm/shortuuid](https://hexdocs.pm/shortuuid).

## Acknowledgments

Inspired by [shortuuid](https://github.com/skorokithakis/shortuuid).

## Copyright and License

Copyright (c) 2019 Goran Pedić

This work is free. You can redistribute it and/or modify it under the
terms of the MIT License. 

See the [LICENSE.md](./LICENSE.md) file for more details.
