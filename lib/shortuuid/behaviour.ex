defmodule ShortUUID.Behaviour do
  @moduledoc """
  Defines the behavior for ShortUUID-compatible modules.

  This behavior ensures consistent interface across different ShortUUID implementations.
  Any module implementing this behavior should provide encode/decode functionality
  for converting UUIDs to shorter string representations and back.

  ## Required Callbacks

  - `encode/1` - Encodes a standard UUID into a shorter string
  - `encode!/1` - Encodes a UUID, raising an exception on invalid input
  - `decode/1` - Decodes a shortened UUID string back into standard UUID format
  - `decode!/1` - Decodes a shortened UUID, raising an exception on invalid input
  """

  @doc """
  Encodes a UUID string into a shorter string representation.

  ## Parameters

  - `uuid` - A standard UUID string (with or without hyphens)

  ## Returns

  - `{:ok, encoded}` - Successfully encoded string
  - `{:error, message}` - Error with descriptive message
  """
  @callback encode(uuid :: String.t()) :: {:ok, String.t()} | {:error, String.t()}

  @doc """
  Encodes a UUID string into a shorter string representation.
  Raises an ArgumentError if the input is invalid.

  ## Parameters

  - `uuid` - A standard UUID string (with or without hyphens)

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
