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
{:ok, "EwQd7sRtDbyyB6QRSWAtQn"}

iex> "f98e80e7-9923-4173-8408-98f8254912ad" |> ShortUUID.encode!
"EwQd7sRtDbyyB6QRSWAtQn"

iex> "EwQd7sRtDbyyB6QRSWAtQn" |> ShortUUID.decode
{:ok, "f98e80e7-9923-4173-8408-98f8254912ad"}

iex> "EwQd7sRtDbyyB6QRSWAtQn" |> ShortUUID.decode!
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
terms of the MIT License. See the [LICENSE.md](./LICENSE.md) file for more details.
