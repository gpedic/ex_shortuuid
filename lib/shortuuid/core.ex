defmodule ShortUUID.Core do
  import Bitwise

  @doc false
  def parse_uuid(<<a::binary-size(8), ?-, b::binary-size(4), ?-, c::binary-size(4), ?-,
        d::binary-size(4), ?-, e::binary-size(12)>>) do
    {:ok, <<a::binary-size(8), b::binary-size(4), c::binary-size(4), d::binary-size(4), e::binary-size(12)>>}
  end

  def parse_uuid(<<_::binary-size(32)>> = uuid), do: {:ok, uuid}

  def parse_uuid(<<?{, uuid::binary-size(36), ?}>>), do: parse_uuid(uuid)
  def parse_uuid(<<?{, uuid::binary-size(32), ?}>>), do: {:ok, uuid}

  def parse_uuid(_), do: {:error, "Invalid UUID"}

  @doc false
  def encode_binary(<<a::binary-size(8), ?-, b::binary-size(4), ?-, c::binary-size(4), ?-,
        d::binary-size(4), ?-, e::binary-size(12)>>, base, alphabet_tuple, encoded_length, padding) do
    encode_uuid_string(
      <<a::binary-size(8), b::binary-size(4), c::binary-size(4), d::binary-size(4), e::binary-size(12)>>,
      base, alphabet_tuple, encoded_length, padding)
  end

  def encode_binary(<<_::binary-size(32)>> = uuid, base, alphabet_tuple, encoded_length, padding) do
    encode_uuid_string(uuid, base, alphabet_tuple, encoded_length, padding)
  end

  def encode_binary(<<?{, a::binary-size(8), ?-, b::binary-size(4), ?-, c::binary-size(4), ?-,
        d::binary-size(4), ?-, e::binary-size(12), ?}>>, base, alphabet_tuple, encoded_length, padding) do
    encode_uuid_string(
      <<a::binary-size(8), b::binary-size(4), c::binary-size(4), d::binary-size(4), e::binary-size(12)>>,
      base, alphabet_tuple, encoded_length, padding)
  end

  def encode_binary(<<?{, uuid::binary-size(32), ?}>>, base, alphabet_tuple, encoded_length, padding) do
    encode_uuid_string(<<uuid::binary-size(32)>>, base, alphabet_tuple, encoded_length, padding)
  end

  def encode_binary(_, _, _, _, _), do: {:error, "Invalid UUID"}

  defp encode_uuid_string(uuid, base, alphabet_tuple, encoded_length, padding) do
    case Base.decode16(uuid, case: :mixed) do
      {:ok, decoded_uuid} -> encode_int(decoded_uuid, base, alphabet_tuple, encoded_length, padding)
      _ -> {:error, "Invalid UUID"}
    end
  end

  @doc false
  def encode_int(<<int_value::128>>, base, alphabet_tuple, encoded_length, padding_char) do
    encoded =
      int_to_string(int_value, base, alphabet_tuple)
      |> pad_string(encoded_length, padding_char)

    if String.length(encoded) == encoded_length do
      {:ok, encoded}
    else
      {:error, "Encoding resulted in incorrect length"}
    end
  end

  defp pad_string(string, length, padding_char) do
    padding_length = length - String.length(string)
    String.duplicate(to_string(padding_char), max(0, padding_length)) <> string
  end

  @doc false
  def decode_string(string, base, codepoint_index, encoded_length) when is_binary(string) do
    with true <- String.length(string) == encoded_length,
         {:ok, value} <- decode_to_int(string, base, codepoint_index),
         true <- value >>> 128 == 0 do
      # Format the UUID after verifying it's within valid range
      {:ok, format_uuid(value)}
    else
      _ -> {:error, "Invalid input"}
    end
  end

  def decode_string(_, _, _, _), do: {:error, "Invalid input"}

  @doc false
  def format_uuid(int_value) when is_integer(int_value) do
    <<int_value::128>>
    |> Base.encode16(case: :lower)
    |> insert_dashes()
  end

  defp insert_dashes(<<a::binary-size(8), b::binary-size(4), c::binary-size(4),
                      d::binary-size(4), e::binary-size(12)>>) do
    a <> "-" <> b <> "-" <> c <> "-" <> d <> "-" <> e
  end

  defp decode_to_int(string, base, codepoint_index) do
    string
    |> String.to_charlist()
    |> Enum.reduce_while({:ok, 0}, fn char, {:ok, acc} ->
      case Map.fetch(codepoint_index, char) do
        {:ok, value} -> {:cont, {:ok, acc * base + value}}
        :error -> {:halt, {:error, "Invalid character"}}  # Return error instead of continuing
      end
    end)
  end

  defp int_to_string(number, base, alphabet_tuple, acc \\ [])
  defp int_to_string(0, _, _, acc), do: to_string(acc)
  defp int_to_string(number, base, alphabet_tuple, acc) when number > 0 do
    int_to_string(
      div(number, base),
      base,
      alphabet_tuple,
      [elem(alphabet_tuple, rem(number, base)) | acc]
    )
  end
end
