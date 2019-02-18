[![Build Status](https://travis-ci.com/gpedic/ex_shortuuid.svg?branch=master)](https://travis-ci.com/gpedic/ex_shortuuid)
[![Coverage Status](https://coveralls.io/repos/github/gpedic/ex_shortuuid/badge.svg)](https://coveralls.io/github/gpedic/ex_shortuuid)
[![Hex.pm](https://img.shields.io/hexpm/v/shortuuid.svg)](https://hex.pm/packages/shortuuid)

# ShortUUID

ShortUUID is a simple Elixir library that generates concise, unambiguous, URL-safe UUIDs.

Often, one needs to use non-sequential IDs in places where users will see them, but the IDs must be as concise and easy to use as possible. ShortUUID solves this problem by translating regular UUIDs to base57 using lowercase and uppercase letters and digits, and removing similar-looking characters such as l, 1, I, O and 0.

Inspired by [shortuuid](https://github.com/skorokithakis/shortuuid).

**Note:** As long as the they use the same alphabet (_23456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz_) different shortuuid implementations should be compatible, however there is no official standard afaik so I would strongly advise to do your own research and compatibility testing if you're doing any sort of interoperability between different libraries.

Unlike other shortuuid libraries this one does not generate UUIDs as this would break with the single task principle and also add potential unneeded dependencies. You can feed any valid UUID into `ShortUUID.encode/1`. Some of the libraries you can use to generate UUIDs are
[Elixir UUID](https://github.com/zyro/elixir-uuid), [Erlang UUID](https://github.com/okeuday/uuid) and also [Ecto](https://hexdocs.pm/ecto/Ecto.UUID.html) as it can generate version 4 UUIDs.

ShortUUID supports the most common formats of UUIDs:
```elixir
  "2A162EE5-02F4-4701-9E87-72762CBCE5E2"
  "2a162ee5-02f4-4701-9e87-72762cbce5e2"
  "2a162ee502f447019e8772762cbce5e2"
  "{2a162ee5-02f4-4701-9e87-72762cbce5e2}"
  "{2a162ee502f447019e8772762cbce5e2}"
```

## Installation

Add ShortUUID to your list of dependencies in `mix.exs`:

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
