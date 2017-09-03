# ShortUUID

ShortUUID is a simple UUID shortener library for Elixir inspired by [shortuuid](https://github.com/skorokithakis/shortuuid).
When used with the same alphabet it should be compatible with the python versions encoder/decoder.
This library does not however support generating UUIDs, some libraries that can be used for that purpose are
[Elixir UUID](https://github.com/zyro/elixir-uuid) and [Erlang UUID](https://github.com/okeuday/uuid) and also [Ecto](https://hexdocs.pm/ecto/Ecto.UUID.html).

## Installation
1. Add ShortUUID to your list of dependencies in `mix.exs`:
  
    ```elixir
    def deps do
      [{:shortuuid, "~> 1.0.0"}]
    end
    ```
 
2. Optionally configure the alphabet to be used for encoding in `config.exs`:

    ```elixir
    config :shortuuid,
      alphabet: "23456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
    ```
 
    The default alphabet (above) will translate UUIDs to base57 using lowercase and uppercase letters
    and digits while avoiding similar-looking characters such as l, 1, I, O and 0.
    

## Documentation

Look up the full documentation at [https://hexdocs.pm/shortuuid](https://hexdocs.pm/shortuuid).
