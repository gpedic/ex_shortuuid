defmodule ShortUUID do
  @moduledoc """
  ShortUUID is a module for encoding and decoding UUIDs using a base57 alphabet.

  ## Functions

  - `encode/1` - Encodes a UUID into a shorter string using base57 alphabet
  - `encode!/1` - Same as encode/1 but raises an error on failure
  - `decode/1` - Decodes a shortened string back into a UUID
  - `decode!/1` - Same as decode/1 but raises an error on failure

  ## Example

      iex> ShortUUID.encode("550e8400-e29b-41d4-a716-446655440000")
      {:ok, "H9cNmGXLEc8NWcZzSThA9S"}

      iex> ShortUUID.decode("H9cNmGXLEc8NWcZzSThA9S")
      {:ok, "550e8400-e29b-41d4-a716-446655440000"}

  For custom alphabets and more options, see `ShortUUID.Builder`.
  To implement your own compatible ShortUUID module, use `ShortUUID.Behaviour`.
  """
  use ShortUUID.Builder, alphabet: :base57_shortuuid
end
