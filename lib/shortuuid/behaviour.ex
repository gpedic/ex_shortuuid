defmodule ShortUUID.Behaviour do
  @moduledoc """
  Defines the behaviour for ShortUUID-compatible modules.

  Modules created with `ShortUUID.Builder` implement this behaviour and meet
  the contract below. Hand-written implementations should meet it too, so that
  code using them (for example an Ecto type) can rely on it.

  ## Contract

  - `encode/1` accepts a UUID string in any of the formats listed in the
    README (with or without hyphens, in curly braces or as a `urn:uuid:` URN),
    in any letter case. It returns `{:ok, short_id}`, or `{:error, message}`
    for anything else.
  - `decode/1` returns `{:ok, uuid}` with a lowercase, hyphenated UUID, and
    accepts exactly the strings that `encode/1` produces: every UUID has one
    short ID, and decoding it and encoding the result gives the same short ID.
    Any other input returns `{:error, message}`.
  - `encode/1` and `decode/1` never raise. Any term, including non-strings and
    invalid UTF-8, returns `{:error, message}` instead.
  - `encode!/1` and `decode!/1` return the value directly and raise an
    `ArgumentError` where the non-bang version returns an error.

  ## Required Callbacks

  - `encode/1` - Encodes a standard UUID into a shorter string
  - `encode!/1` - Encodes a UUID, raising an exception on invalid input
  - `decode/1` - Decodes a shortened UUID string back into standard UUID format
  - `decode!/1` - Decodes a shortened UUID, raising an exception on invalid input
  """

  @doc """
  Encodes a UUID string into a shorter string representation.

  ## Parameters

  - `uuid` - A UUID string in one of the supported formats

  ## Returns

  - `{:ok, encoded}` - Successfully encoded string
  - `{:error, message}` - Error with descriptive message
  """
  @callback encode(uuid :: String.t()) :: {:ok, String.t()} | {:error, String.t()}

  @doc """
  Encodes a UUID string into a shorter string representation.
  Raises an ArgumentError if the input is invalid.

  ## Parameters

  - `uuid` - A UUID string in one of the supported formats

  ## Returns

  - `encoded` - Successfully encoded string

  ## Raises

  - `ArgumentError` - If the input is invalid
  """
  @callback encode!(uuid :: String.t()) :: String.t() | no_return()

  @doc """
  Decodes a shortened UUID string back into standard UUID format.

  ## Parameters

  - `string` - A shortened UUID string

  ## Returns

  - `{:ok, uuid}` - Successfully decoded UUID
  - `{:error, message}` - Error with descriptive message
  """
  @callback decode(string :: String.t()) :: {:ok, String.t()} | {:error, String.t()}

  @doc """
  Decodes a shortened UUID string back into standard UUID format.
  Raises an ArgumentError if the input is invalid.

  ## Parameters

  - `string` - A shortened UUID string

  ## Returns

  - `uuid` - Successfully decoded UUID

  ## Raises

  - `ArgumentError` - If the input is invalid
  """
  @callback decode!(string :: String.t()) :: String.t() | no_return()
end
